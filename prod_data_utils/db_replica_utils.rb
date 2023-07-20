require 'json'
require 'zlib'
require 'net/http'
require 'aws-sdk-rds'
require 'time'
require 'logger'
require 'fileutils'
require "yaml"

# This script does following things:
# 1. create a read replica off target database
# 2. establish application connection to the read replica db
# 3. kill the replica instance after running data checks (on demand)


class DbReplicaUtils

  attr_reader :rds

  def initialize(config = JSON.parse(File.read('prod_data_utils/config.json')), environment, logger: nil)
    # Logger
    @logger = logger
    @logger = Logger.new('prod_data_utils/logs/db_replica_utils.log', 'daily') unless @logger
    @logger.level = Logger::DEBUG

    # Make Config Globally Accessible
    @config = config
    @environment = environment

    # DB instance variables
    @master_source_id = @config['app']['master_source_id']
    @replica_instance_id = @config['app']['replica_instance_id']
    @db_conn = @config['db']

    # add timestamp to avoid duplication
    if @config['app']['always_create_replica'] == '1'
      @replica_instance_id += "-#{@environment}-#{@config['version'].gsub('.','-')}-#{DateTime.now.strftime('%Y%m%d-%H%M%I')}"
    else
      @replica_instance_id += "-#{@environment}-#{@config['version'].gsub('.','-')}"
    end

    # Configure AWS
    Aws.config.update({
      region: @config['aws']['region'],
      credentials: Aws::Credentials.new(@config['aws']['aws_access_key_id'], @config['aws']['aws_secret_access_key'])
    })
  
    # AWS RDS Connection   
    @rds = Aws::RDS::Client.new
    
    # Cloud Watch Connection
    @cw = Aws::CloudWatch::Client.new
  end
  
  # EXECUTE SCRIPT **********************************************

  def run
    unless check_instance_exists(@replica_instance_id)
      create_read_replica(@master_source_id, @replica_instance_id)
      promote_read_replica(@replica_instance_id)

      switch_app_to_read_replica
    end


  end

  
  # AWS RDS METHODS **********************************************

  def create_read_replica(source_id, dest_id)
    begin
      @logger.info "Creating Read Replica for #{source_id}"
      response = @rds.create_db_instance_read_replica({db_instance_identifier: dest_id, source_db_instance_identifier: source_id})
      @logger.info "Create Read Replica Results:"
      @logger.info "DB Instance Identifier = #{response.db_instance.db_instance_identifier}"
      @logger.info "DB Instance Status = #{response.db_instance.db_instance_status}"
      @logger.info "Read Replica Source DB Instance Identifier = #{response.db_instance.read_replica_source_db_instance_identifier}"
      check_status(dest_id, "available", 360) # Times out after 6hr
    rescue Exception => e
      @logger.error "Unable to complete create_read_replica. Error: #{e.message}."
      abort
    end
  end

  def promote_read_replica(dest_id)
    begin
      @logger.info "Promoting Read Replica #{dest_id}"
      app_env = @environment
      response = @rds.promote_read_replica({
                                               backup_retention_period: 1,
                                               db_instance_identifier: dest_id,
                                               preferred_backup_window: @config['app']['preferred_backup_window'] || "03:30-04:00",
                                           })
      @logger.info "Promote Read Replica Results:"
      @logger.info "DB Instance Identifier = #{response.db_instance.db_instance_identifier}"
      @logger.info "DB Instance Status = #{response.db_instance.db_instance_status}"
      check_status(dest_id, "available", 360) # Times out after 6hr

      @logger.info "Modify Promoted Read Replica"
      modify_response = @rds.modify_db_instance({
                                                    db_instance_identifier: dest_id,
                                                    apply_immediately: true,
                                                    db_instance_class: (@config['app'][app_env] || {})['db_instance_class'] || "db.m4.large"
                                                })
      check_status(dest_id, "available", 360) # Times out after 6hr

    rescue Exception => e
      @logger.error "Unable to complete promote_read_replica. Error: #{e.message}."
      abort
    end
  end
  
  # Method used to see if AWS process completed
  # Default timeout set to 60 min (seconds * retry attempts)
  def check_status(instance_id, status, retry_attempts=60, seconds=60)
    begin
      check_status_timeout = seconds * retry_attempts
      @logger.info "Check Status Timeout = #{check_status_timeout} sec"
      @logger.info "Expected Status = #{status}"

      for i in 1..retry_attempts
        sleep seconds
        db_instance_status = @rds.describe_db_instances({db_instance_identifier: instance_id}).db_instances[0].db_instance_status
        @logger.info "(Attempt #{i} of #{retry_attempts}) Checking DB Status, current value is:  #{db_instance_status}"
        return if "#{db_instance_status}".downcase == "#{status}".downcase  
      end
      @logger.error "Check status timeout limit of #{check_status_timeout} sec reached. Expected status of #{status}. Current status is #{db_instance_status}."
      abort
    rescue Exception => e
      @logger.error "Unable to complete check_status. Error: #{e.message}."
      abort
    end
  end

  # Check db instance exists or not
  def check_instance_exists(instance_id)
    begin
      @logger.info "Describing #{instance_id}"
      response = @rds.describe_db_instances({db_instance_identifier: instance_id})
      
      response.db_instances.any?
    rescue Exception => e
      @logger.error "Unable to locate instance #{instance_id}. Error: #{e.message}."
      false
    end
  end

  # Endpoint URL is needed to establish db connection
  def get_replica_instance_endpoint(instance_id = @replica_instance_id)
    begin
      @logger.info "Getting endpoint URL for instance #{instance_id}"
      response = @rds.describe_db_instances({db_instance_identifier: instance_id})
      
      if !response.db_instances || response.db_instances.empty?
        @logger.error "Couldn't locate instance #{instance_id}."
        abort
      end

      replica_url = response.db_instances[0].endpoint.address
      @logger.info "Instance endpoint URL: #{replica_url}"
      
      replica_url
    rescue Exception => e
      @logger.error "Unable to locate instance #{instance_id}. Error: #{e.message}."
    end
  end

  def connect_to_read_replica(instance_id = @replica_instance_id)
    begin
      @logger.info "Connecting to db instance #{instance_id}"
      @db_conn[:host] = get_replica_instance_endpoint(instance_id)

      ActiveRecord::Base.establish_connection @db_conn

      @logger.info "DB connection made"
    rescue Exception => e
      @logger.error "Unable to connect to db instance #{instance_id}. Error: #{e.message}."
      abort
    end
  end

  def switch_app_to_read_replica(instance_id = @replica_instance_id)
    begin
      @logger.info "Switching app to db instance #{instance_id}"
      @db_conn[:host] = get_replica_instance_endpoint(instance_id)

      # # Modify application.yml pointing to new db
      # yml_data = load_application_yaml
      # app_env = @config['app']['environment']
      # yml_data[app_env]['DB_HOST'] = @db_conn[:host]
      # yml_data[app_env]['DB_SCHEMA']= @db_conn['database']
      #
      # write_application_yaml yml_data

      switch_route53_db_cname

      @logger.info "App switched to new db"
    rescue Exception => e
      @logger.error "Unable to switch to db instance #{instance_id}. Error: #{e.message}."
      abort
    end
  end

  def switch_route53_db_cname(route53_config = JSON.parse(File.read('prod_data_utils/route53_config.json')))

    @route53 = Aws::Route53::Client.new(
        region: route53_config['aws']['region'],
        credentials: Aws::Credentials.new(route53_config['aws']['aws_access_key_id'], route53_config['aws']['aws_secret_access_key'])
    )

    resp = @route53.change_resource_record_sets({
         change_batch: {
             changes: [
                 {
                     action: "UPSERT",
                     resource_record_set: {
                         name: "#{@config['app']['app']}-#{@environment}.db.camsys-apps.com",
                         resource_records: [
                             {
                                 value: @db_conn[:host],
                             },
                         ],
                         ttl: 60,
                         type: "CNAME",
                     },
                 },
             ]
         },
         hosted_zone_id: route53_config['app']['hosted_zone_id'],
     })

    check_route53_status(resp.change_info.id, 'insync',360) # check status for 6 hours

  end

  # Method used to see if AWS process completed
  # Default timeout set to 60 min (seconds * retry attempts)
  def check_route53_status(instance_id, status, retry_attempts=60, seconds=60)
    begin
      check_status_timeout = seconds * retry_attempts
      @logger.info "Check Status Timeout = #{check_status_timeout} sec"
      @logger.info "Expected Status = #{status}"

      for i in 1..retry_attempts
        sleep seconds
        route53_status = @route53.get_change({id: instance_id}).change_info.status
        @logger.info "(Attempt #{i} of #{retry_attempts}) Checking DB Status, current value is:  #{route53_status}"
        return if "#{route53_status}".downcase == "#{status}".downcase
      end
      @logger.error "Check status timeout limit of #{check_status_timeout} sec reached. Expected status of #{status}. Current status is #{route53_status}."
      abort
    rescue Exception => e
      @logger.error "Unable to complete check_status. Error: #{e.message}."
      abort
    end
  end

  def load_application_yaml
    begin
      @logger.info "Parsing application.yml"
      yml_path = "#{Rails.root}#{@config['app']['application_yml_path']}"
      yml_data = YAML.load_file yml_path
      
      yml_data
    rescue Exception => e
      @logger.error "Unable to parse application.yml at #{yml_path}. Error: #{e.message}."
      abort
    end
  end

  def write_application_yaml(yml_data)
    begin
      @logger.info "Writing application.yml"
      yml_path = "#{Rails.root}#{@config['app']['application_yml_path']}"
      File.open(yml_path, 'w') { |f| YAML.dump(yml_data, f) }
    rescue Exception => e
      @logger.error "Unable to write application.yml at #{yml_path}. Error: #{e.message}."
      abort
    end
  end

  def kill_replica_instance(instance_id = @replica_instance_id)
    begin
      @logger.info "Deleting replica instance #{instance_id}"
      response = @rds.delete_db_instance({ db_instance_identifier: instance_id, skip_final_snapshot: true})
      @logger.info "Instance deleted"
    rescue Exception => e
      @logger.error "Unable to delete instance #{instance_id}. Error: #{e.message}."
      abort
    end
  end

end


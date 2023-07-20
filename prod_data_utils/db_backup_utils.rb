class DbBackupUtils

  attr_reader :rds

  def initialize(config = JSON.parse(File.read('prod_data_check/config.json')), version, environment, logger: nil)
    # Logger
    @logger = logger
    @logger = Logger.new('prod_data_check/logs/db_backup_utils.log', 'daily') unless @logger
    @logger.level = Logger::DEBUG

    @config = config
    @environment = environment

    # DB instance variables
    @master_source_id = @config['app']['master_source_id']
    @db_conn = @config['db']
    @snapshot_id = "backup-before-#{version.gsub('.','-')}"

    # Configure AWS
    Aws.config.update({
                        region: @config['aws']['region'],
                        credentials: Aws::Credentials.new(@config['aws']['aws_access_key_id'], @config['aws']['aws_secret_access_key'])
                      })

    # AWS RDS Connection   
    @rds = Aws::RDS::Client.new
  end

  def run
    unless check_snapshot_exists(@snapshot_id)
      create_snapshot(@master_source_id, @snapshot_id)
      wait_for_snapshot_available(@snapshot_id)
    end
  end

  # Helper methods

  def check_snapshot_exists(id)
    begin
      @logger.info "Describing #{id}"
      response = @rds.describe_db_snapshots({db_snapshot_identifier: id})
      response.db_snapshots.any?
    rescue Exception => e
      @logger.error "Unable to locate instance #{id}. Error: #{e.message}"
      false
    end
   end

  def create_snapshot(db_id, snaphshot_id)
    begin
      @logger.info "Creating backup snapshot for #{db_id}"
      response = @rds.create_db_snapshot({db_instance_identifier: db_id, db_snapshot_identifier: snaphshot_id})
    rescue Exception => e
      @logger.error "Unable to create snapshot. Error: #{e.message}"
      abort
    end
  end

  def wait_for_snapshot_available(id)
    begin
      @logger.info "Waiting for snapshot #{id} to become available"
      resp = rds.wait_until(:db_snapshot_available, {db_snapshot_identifier: id})
      @logger.info "Snapshot #{id} available"
    rescue Exception => e
      @logger.error "Unable to wait for snapshot available. Error: #{e.message}"
      abort
    end
  end

end

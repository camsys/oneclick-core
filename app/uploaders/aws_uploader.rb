
# Uploads files or data to an AWS S3 bucket
# TODO: Configure to 'upload' to local file system as well
class AwsUploader
  
  attr_accessor :root_path, # The folder in the AWS S3 bucket to upload all files to
                :s3_region, # The region code for the AWS S3 bucket (e.g. 'us-east-1')
                :aws_bucket_name, # The name of the AWS S3 bucket (e.g. 'occ-dev')
                :aws_access_key_id,
                :aws_secret_access_key
                
  attr_reader   :bucket # A bucket object created based on the above configs
                
  def initialize(opts={})
    
    @root_path = opts[:root_path] || "/"
    
    @s3_region = opts[:s3_region] || ENV['S3_REGION']
    @aws_bucket_name = opts[:aws_bucket_name] || ENV['AWS_BUCKET']
    @aws_access_key_id = opts[:aws_access_key_id] || ENV['AWS_ACCESS_KEY_ID']
    @aws_secret_access_key = opts[:aws_secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY']
  
    if valid?
      update_aws_config
      setup_bucket
    end
    
  end
  
  # Updates the AWS config object with access credentials
  def update_aws_config
    Aws.config.update({
      access_key_id: @aws_access_key_id,
      secret_access_key: @aws_secret_access_key
    })
  end
  
  # Sets the bucket instance variable to an AWS bucket object based on config variables
  def setup_bucket
    @bucket = Aws::S3::Resource.new(region: @s3_region).bucket(@aws_bucket_name)
  end
  
  # Returns a reference to an object on S3 based on the given file name
  def object(name)
    @bucket.object(@root_path + name)
  end
  
  # Uploads a file from the local file system to the given path in the bucket
  # Accepts public: true or public: false options
  def upload_file(from_path, file_name, opts={})
    return false unless valid?
    pub = !!opts[:public]
    object(file_name).upload_file(from_path)
    make_public(file_name) if pub
  end
  
  # Uploads hash as JSON directly to the given path
  # Accepts public: true or public: false options
  def upload_json(hash, file_name, opts={})
    return false unless valid?
    pub = !!opts[:public]
    object(file_name).put(body: hash.to_json)
    make_public(file_name) if pub
  end
  
  # Makes a given file on the bucket public-readable
  def make_public(file_name)
    object(file_name).acl.put({acl: "public-read"})
  end
  
  # Makes a given file on the bucket private
  def make_private(file_name)
    object(file_name).acl.put({acl: "private"})
  end
  
  # Uploader is valid if all AWS variables are set
  def valid?
    @s3_region && @aws_bucket_name && @aws_access_key_id && @aws_secret_access_key
  end
  
end

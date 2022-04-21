CarrierWave.configure do |config|
  config.aws_credentials = {
      :provider               => 'AWS',
      :region                 => ENV['S3_REGION'] || "us-east-1" # Change this for different AWS region. Default is 'us-east-1'
  }
  config.aws_bucket  = ENV['AWS_BUCKET'] || "none"
end

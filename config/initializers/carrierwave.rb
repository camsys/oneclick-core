CarrierWave.configure do |config|
  config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'] || "none",
      :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'] || "none",
      :region                 => ENV['S3_REGION'] || "us-east-1" # Change this for different AWS region. Default is 'us-east-1'
  }
  config.fog_directory  = ENV['AWS_BUCKET'] || "none"
end

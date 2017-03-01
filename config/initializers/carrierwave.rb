CarrierWave.configure do |config|
  config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => ENV['S3_KEY'] || "none",
      :aws_secret_access_key  => ENV['S3_SECRET'] || "none"
      # :region                 => ENV['S3_REGION'] # Change this for different AWS region. Default is 'us-east-1'
  }
  config.fog_directory  = ENV['S3_BUCKET'] || "none"
end

module Logoable
  
  # Mount logo uploader to including class
  def self.included(base)
    base.mount_uploader :logo, LogoUploader  
    base.extend(ClassMethods)
  end

  module ClassMethods
  end

  ### INSTANCE METHODS ###
  
  # Returns a full logo url. By default, sends thumbnail version.
  def full_logo_url(version=:thumb)
    logo_version = version.nil? ? logo : logo.send(version)
    ActionController::Base.helpers.asset_path(logo_version.url.to_s)
  end
  
end

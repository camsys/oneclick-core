module TranslationModelExtensions
  
  # Initialize a single AwsLocaleUploader that all including classes will have access to.
  mattr_accessor :aws_locale_uploader
  self.aws_locale_uploader = AwsLocaleUploader.new

  extend ActiveSupport::Concern

  included do    
    # If any changes were made to the model, upload all locales as json to AWS
    after_commit :upload_translations_json, if: :previous_changes?
  end
  
  def upload_translations_json
    self.aws_locale_uploader.upload_all
  end
  
  def previous_changes?
    self.previous_changes.present?
  end

end

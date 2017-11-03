module TranslationModelExtensions

  extend ActiveSupport::Concern

  included do
    
    # If any changes were made to the model, upload all locales as json to AWS
    after_commit :upload_translations_json, if: :previous_changes?
    
  end
  
  def upload_translations_json
    AwsLocaleUploader.new.upload_all
  end
  
  def previous_changes?
    self.previous_changes.present?
  end

end

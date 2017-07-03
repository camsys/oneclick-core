Rails.configuration.to_prepare do

  TranslationsController.class_eval do
    include TranslationsExtensions
    
    authorize_resource
  end

end

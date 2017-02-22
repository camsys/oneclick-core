Rails.configuration.to_prepare do

  TranslationsController.class_eval do
    include TranslationsExtensions
  end

  Config.class_eval do 
  	include TestExtensions
  end

end
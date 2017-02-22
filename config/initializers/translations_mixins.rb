Rails.configuration.to_prepare do

  TranslationsController.class_eval do
    include TranslationsExtensions
  end

end
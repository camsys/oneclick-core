
# Uploads locale (i18n/translations) JSON files to AWS S3 bucket
class LocaleUploader
  
  def initialize(opts={})
    # AwsUploader class handles basic logic of configuring, uploading to, 
    # and setting permissions on AWS buckets
    @aws_uploader = AwsUploader.new(root_path: "i18n/")
  end
  
  # Uploads translations json files for all available locales, as well as keys
  def upload_all
    I18n.available_locales.each { |loc| upload_locale(loc) }
    upload_keys
  end
  
  # build and uploads a json file of translations for the given locale
  def upload_locale(locale=I18n.default_locale)
    @aws_uploader.upload_json(
      build_translations_hash(locale), # Build a hash of all translations for the locale
      "#{locale}.json", # Name the file after the locale
      public: true  # Make the file publicly readable
    )
  end
  
  # Uploads a json file that maps the TranslationKeys one to one onto themselves
  def upload_keys
    filename = "keys.json"
    keys_hash = TranslationKey.pluck(:name)
                              .compact
                              .map { |k| [k,k] }
                              .to_h
    @aws_uploader.upload_json(keys_hash, "keys.json", public: true)
  end
  
  # builds a translations hash for the given locale
  def build_translations_hash(locale=I18n.default_locale)
    loc_model = Locale.find_by(name: locale) # The model object for the given locale
    
    TranslationKey.all.map do |tkey|
      [
        tkey.name, 
        tkey.translation(loc_model).try(:value)
      ]
    end.to_h
  end
  
end

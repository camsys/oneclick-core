module Api
  module V1
    class TranslationsController < ApiController

      def find

        locale = Locale.find_by(name:  params[:lang] || params[:locale])
        translations = params[:translations]
        translated = {}

        translations.each do |translation|

          key = TranslationKey.find_by(name: translation)
          unless key.nil?
            trans = Translation.find_by(locale: locale, translation_key: key)
          end

          #The gsub finds all instances of %{xyz} and replaces then with {{xyz}} The {{xyz}} string is used by Angular for interpolation
          translated[translation] = trans.nil? ? nil : trans.value.to_s.gsub(/%\{[a-zA-Z_]+\}/) { |s| '{{' + s[2..-2] + '}}' }
        end

        render status: 200, json: translated
        return

      end


      def all
        dictionaries = {}

        if params[:auto_translate].to_i == 1
          google_api_key = ENV['GOOGLE_API_KEY']

          translator = (google_api_key ? GoogleTranslator.new(google_api_key) : DummyTranslator.new).from(I18n.default_locale)
          source_locale = Locale.of(I18n.default_locale)
        end


        if params[:lang] || params[:locale]
          locale = Locale.find_by_name(params[:lang] || params[:locale])
          dictionary = {} #Translation.where(locale: locale).each {|t| {t.key => t.value}}

          #The gsub finds all instances of %{xyz} and replaces then with {{xyz}} The {{xyz}} string is used by Angular for interpolation
          Translation.where(locale: locale).each {|translation| dictionary[translation.key] = translation.value.to_s.gsub(/%\{[a-zA-Z_]+\}/) { |s| '{{' + s[2..-2] + '}}' } }

          if params[:auto_translate].to_i == 1
            translator = translator.to(locale.name)

            Translation.joins(:translation_key).where(translation_key: TranslationKey.visible.where.not(id: Translation.where(locale: locale).select(:translation_key_id)), locale: source_locale).pluck('translation_keys.name', 'value').each do |t|
              source_translation = t[1]
              target_translation = translator.translate(source_translation)
              dictionary[t[0]] = target_translation
            end
          end

          dictionary = add_v1_translations dictionary

          dictionaries = dictionary

        else
          Locale.all.each do |locale|
            dictionary = {} #Translation.where(locale: locale).map {|t| {t.key => t.value}}

            #The gsub finds all instances of %{xyz} and replaces then with {{xyz}} The {{xyz}} string is used by Angular for interpolation
            Translation.where(locale: locale).each {|translation| dictionary[translation.key] = translation.value.to_s.gsub(/%\{[a-zA-Z_]+\}/) { |s| '{{' + s[2..-2] + '}}' } }

            if params[:auto_translate].to_i == 1
              translator = translator.to(locale.name)

              Translation.joins(:translation_key).where(translation_key: TranslationKey.visible.where.not(id: Translation.where(locale: locale).select(:translation_key_id)), locale: source_locale).pluck('translation_keys.name', 'value').each do |t|
                source_translation = t[1]
                target_translation = translator.translate(source_translation)
                dictionary[t[0]] = target_translation
              end
            end

            dictionaries[locale.name] = add_v1_translations dictionary
          end
        end

        render status: 200, json: dictionaries
        return
      end

      def locales
        google_api_key = ENV['GOOGLE_API_KEY']

        if google_api_key
          translator = GoogleTranslator.new(google_api_key,target: params[:lang] || params[:locale])

          languages = translator.locales.map{|h| h.values}.to_h

          locales_arr = Locale.where(name: I18n.available_locales.sort).pluck(:name).each_with_object({}) do |language_code,h|
            language_name = languages[language_code]

            h.update(language_code=>language_name)
          end
        else
          locales_arr = {}
        end

        render status: 200, json: locales_arr
      end

      # OCC uses translations like eligibilty_wheelchair_note, but V1 is looking for wheelchair_note.
      # Do this for all eligbilities, accommodations, and purposes
      def add_v1_translations dictionary

        ['eligibility', 'accommodation', 'purpose'].each do |trans_type|

          trans = dictionary.keys.select { |key| key.to_s.match(/^#{trans_type}_/) }
          trans.each do |tran|
            new_key = tran.sub("#{trans_type}_", "")
            dictionary[new_key] = dictionary[tran]
          end
        end

        dictionary

      end

    end
  end
end

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

        if params[:lang] || params[:locale]
          locale = Locale.find_by_name(params[:lang] || params[:locale])
          dictionary = {} #Translation.where(locale: locale).each {|t| {t.key => t.value}}

          #The gsub finds all instances of %{xyz} and replaces then with {{xyz}} The {{xyz}} string is used by Angular for interpolation
          Translation.where(locale: locale).each {|translation| dictionary[translation.key] = translation.value.to_s.gsub(/%\{[a-zA-Z_]+\}/) { |s| '{{' + s[2..-2] + '}}' } }

          dictionary = add_v1_translations dictionary

          dictionaries = dictionary

        else
          Locale.all.each do |locale|
            dictionary = {} #Translation.where(locale: locale).map {|t| {t.key => t.value}}

            #The gsub finds all instances of %{xyz} and replaces then with {{xyz}} The {{xyz}} string is used by Angular for interpolation
            Translation.where(locale: locale).each {|translation| dictionary[translation.key] = translation.value.to_s.gsub(/%\{[a-zA-Z_]+\}/) { |s| '{{' + s[2..-2] + '}}' } }
            dictionaries[locale.name] = dictionary
          end
        end

        render status: 200, json: dictionaries
        return
      end

      # OCC uses translations like eligibilty_wheelchair_note, but V1 is looking for wheelchair_note.  
      # Do this for all eligbilities, accommodations, and purposes
      def add_v1_translations dictionary

        ['eligibility', 'accommodation', 'purpose'].each do |trans_type|

          trans = dictionary.keys.select { |key| key.to_s.match(/^#{trans_type}_/) }
          trans.each do |tran|
            new_key = tran.sub("#{trans_type}_", "")
            puts new_key
            puts trans
            dictionary[new_key] = dictionary[trans]
          end
        end

        dictionary

      end

    end
  end
end

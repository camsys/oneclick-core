namespace :refernet do

  desc "Translate"

  task translate_categories: :environment do 
    new_translations = 0
    ['Category', 'SubCategory', 'SubSubCategory'].each do |model|
      
      # Get the right objects
      case model
      when 'Category'
        cats = OneclickRefernet::Category.all
      when 'SubCategory'
        cats = OneclickRefernet::SubCategory.all
      when 'SubSubCategory'
        cats = OneclickRefernet::SubSubCategory.all
      end

      # Make sure translations exist for those objects
      cats.each do |cat|
        translation = SimpleTranslationEngine.translate(:en, "REFERNET_#{cat.name}")
        unless translation == "missing key REFERNET_#{cat.name}"
          next
        else
          puts "Translating REFERNET_#{cat.name}------------------"
          I18n.available_locales.each do |locale|
            ### Replace THIS with GOOGLE 
            translated = (locale == :en) ? cat.name : locale.to_s + cat.name.to_s
            ########################################
            SimpleTranslationEngine.set_translation(locale, "REFERNET_#{cat.name}", translated)
          end
          new_translations += 1
        end
      end
    end
    
    puts "#{new_translations} new Category Translations"

  end

  task translate_services: :environment do 
    services_translated = 0
    OneclickRefernet::Service.all.each do |service|
      new_description = service['details']["Label_Service Description"]
      old_description = SimpleTranslationEngine.translate(:en, "REFERNET_SERVICE_#{service['details']['Service_ID']}+#{service['details']['ServiceSite_ID']}_description")
      
      if old_description == new_description
        next
      else
        puts "Translating REFERNET_SERVICE_#{service['details']['Service_ID']}+#{service['details']['ServiceSite_ID']}_description ------------------"
        I18n.available_locales.each do |locale|

          ### Replace THIS with GOOGLE 
          translated = (locale == :en) ? new_description : locale.to_s + new_description.to_s
          ########################################
          SimpleTranslationEngine.set_translation(locale, "REFERNET_SERVICE_#{service['details']['Service_ID']}+#{service['details']['ServiceSite_ID']}_description", translated)
        end
        services_translated += 1  
        puts new_description
      end
    end
    puts "Services with new translations: #{services_translated}"
    puts "Services skipped: #{OneclickRefernet::Service.count - services_translated}"
  end

  #"description":  service['details']["Label_Service Description"] || "#{service['details']['Note1']} #{service['details']['Note2']}",

end

namespace :update do
  
  # For Version 1.5.0
  desc "transfer service and agency comments to description translations" 
  task transfer_comments_to_descriptions: :environment do
    [Agency, Service].each do |table|
      table.all.each do |record|
        Comment.where(commentable_type: table.name).each do |comment|
          if comment.commentable
            puts "Setting description for #{comment.commentable.to_s}, locale: #{comment.locale}"
            comment.commentable.set_description_translation(comment.locale, comment.comment)
          end
        end
      end
      
      puts "Destroying comments for #{table.name} table"
      Comment.where(commentable_type: table.name).destroy_all
    end
  end

  # For Versions 1.16.7 and or 1.17.0
  # Rake task finds and updates Penn DOT, and Test Oversight Agency's agencies.type depending on the input arg
  # Has input arg: update_to which accepts 2 values:
  # - :update_to => "partner" : tells the rake task to update the agencies to the PartnerAgency type
  # - :update_to => "oversight" : tells the rake task to update the agencies to the OversightAgency type
  desc "reversibly update seeded Oversight Agencies agencies.type value"
  task :reversibly_update_agency_type,[:update_to] => :environment do |t, args|
    if args[:update_to] == "partner"
      sql = "UPDATE agencies SET type='PartnerAgency' WHERE type='OversightAgency' AND name IN ('Penn DOT', 'Test Oversight Agency')"
      ActiveRecord::Base.connection.execute(sql)
      puts "Updated Penn DOT and Test Oversight Agency to be PartnerAgency"
    elsif args[:update_to] == "oversight"
      sql = "UPDATE agencies SET type='OversightAgency' WHERE type='PartnerAgency' AND name IN ('Penn DOT', 'Test Oversight Agency')"
      ActiveRecord::Base.connection.execute(sql)
      puts "Updated Penn DOT and Test Oversight Agency to be OversightAgency"
    else
      raise "Unexpected value for :update_to, please check release docs or the update.rake file for acceptable inputs for :update_to"
    end
    Rake::Task['update:reversibly_update_role_type'].invoke(args[:update_to])
  end

  desc "reversibly update resource type in roles"
  task :reversibly_update_role_type,[:update_to] => :environment do |t,args|
    if args[:update_to] == "partner"
      roles = Role.where(resource_type: 'OversightAgency')
      roles.update_all(resource_type:'PartnerAgency')
    elsif args[:update_to] == "oversight"
      roles = Role.where(resource_type: 'PartnerAgency')
      roles.update_all(resource_type:'OversightAgency')
    else
      raise "Unexpected value for :update_to, please check release docs or the update.rake file for acceptable inputs for :update_to"
    end
  end

  desc "reversibly update the default user's role"
  task :reversibly_update_default_user_role,[:update_to] => :environment do |t,args|
    default_user = User.find_by email: "1-click@camsys.com"
    if args[:update_to] == "admin"
      default_user.remove_role(:superuser)
      default_user.add_role(:admin)
      puts "updated default user to admin"
    elsif args[:update_to] == "superuser"
      default_user.remove_role(:admin)
      default_user.add_role(:superuser)
      puts "updated default user to superuser"
    else
      raise "Unexpected value for :update_to, please check release docs or the update.rake file for acceptable inputs for :update_to"
    end
  end


  
end

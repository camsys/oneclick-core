
namespace :agency_restriction do
  desc "Add admin role to agencies"
  task add_admin: :environment do
    Agency.all.each do |agency|
      Role.where(name: "admin", resource_id: agency.id, resource_type: agency.class.name).first_or_create
    end
  end

  desc "Add superuser role and change default admin user to superuser"
  task update_default_admin: :environment do
    puts "Updating default admin user to superuser"
    Role.where(name: "superuser").first_or_create
    default = User.find_by(email: "1-click@camsys.com")
    if default.admin?
      default.add_role("superuser")
      default.remove_role("admin")
      puts "Default admin user updated to superuser"
    elsif default.superuser?
      puts "Default admin user is already a superuser"
    end
  end


end
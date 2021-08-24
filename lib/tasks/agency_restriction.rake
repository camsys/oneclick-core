
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

  desc "Sample Unaffiliated Users"
  task unaffiliated_users: :environment do
    us = User.where(email: 'test-unaffiliated-staff@camsys.com').first_or_create do |user|
      user.password = 'guest1'
      user.password_confirmation = 'guest1'
      user.add_role(:staff)
      puts 'Creating test unaffiliated staff user'
    end
    ua = User.where(email: 'test-unaffiliated-admin@camsys.com').first_or_create do |user|
      user.password = 'guest1'
      user.password_confirmation = 'guest1'
      user.add_role(:admin)
      puts 'Creating test unaffiliated admin user'
    end
    us.save
    ua.save
  end

  desc "Seed initial oversight agency and staff"
  task seed_oversight_agency: :environment do
    puts "Seeding default oversight agency"
    oa = OversightAgency.find_or_create_by(name: "Test Oversight Agency",
                                           email: "test_oversight_agency@oneclick.com",
                                           published:true)
    [
      {
        email: "test-oversight-staff@camsys.com",
        password: 'guest1',
        password_confirmation: 'guest1',
      },      {
        email: "test-oversight-admin@camsys.com",
        password: 'guest1',
        password_confirmation: 'guest1',
      },
    ].each_with_index do |json,ind|
      user = User.find_or_create_by(email: json.delete(:email))
      user.password = json[:password]
      user.password_confirmation = json[:password_confirmation]
      if ind == 1
        oa.add_admin(user)
      else
        oa.add_staff(user)
      end
      user.save
    end
  end

end
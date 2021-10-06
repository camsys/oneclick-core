
namespace :agency_restriction do
  desc "Add admin role to agencies"
  task add_admin: :environment do
    Agency.all.each do |agency|
      Role.where(name: "admin", resource_id: agency.id, resource_type: agency.class.name).first_or_create
    end
    puts "added admin roles to agencies"
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

  desc "Seed Unaffiliated Users"
  task seed_unaffiliated_users: :environment do
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
    puts "Seeded unaffiliated staff and admin users"
  end
  desc "Seed Transportation  Users"
  task seed_transportation_users: :environment do
    ta = TransportationAgency.first
    us = User.where(email: 'test-transportation-staff@camsys.com').first_or_create do |user|
      user.password = 'guest1'
      user.password_confirmation = 'guest1'
      ta.add_staff(user)
      puts 'Creating test transportation staff user'
    end
    ua = User.where(email: 'test-transportation-admin@camsys.com').first_or_create do |user|
      user.password = 'guest1'
      user.password_confirmation = 'guest1'
      user.add_role(:admin)
      ta.add_admin(user)
      puts 'Creating test transportation admin user'
    end
    us.save
    ua.save
    puts "Seeded unaffiliated staff and admin users"
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
    puts "Seeded test oversight agency with staff"
  end

  desc "Add Penn DOT oversight agency and associate other transit agencies to it"
  task add_penn_dot: :environment do
    penn_dot = OversightAgency.find_or_create_by(
      name: "Penn DOT",
      published: "true"
    )
    puts "Penn DOT Oversight Agency created with id: #{penn_dot.id}"
  end

  desc "Assigning all Transportation Agencies to Penn DOT"
  task assign_agency_to_penn_dot: :environment do
    penn_dot = OversightAgency.find_by(
      name: "Penn DOT",
      published: "true"
    )
    puts "Assigning all Transportation Agencies to Penn DOT"
    count= 0
    TransportationAgency.all.each do |ta|
      AgencyOversightAgency.create(
        transportation_agency_id: ta.id,
        oversight_agency_id: penn_dot.id)
      count+=1
    end
    puts "#{count} Transportation agencies assigned to Penn DOT"
  end

  desc "Assign staff and admin with an @pa.gov email to Penn DOT"
  task assign_staff_to_penn_dot: :environment do
    # Search for Staff and admin with a pa.gov email
    pa_gov_staff = User.staff_for_none.where("users.email ~* :pagov", :pagov => '\@pa\.gov')
    ar = %w[]
    pa_gov_staff.each do |user|
      # Make all current Penn DOT admin staff by default
      # SHOULD BE UPDATED LATER
      user.remove_role(:admin)
      user.set_staff_role(OversightAgency.find_by(name: 'Penn DOT'))
      ar.push(user.email)
    end

    puts "The following users with emails have been assigned to Penn DOT: #{ar.to_s}"
    puts "NOTE: ALL PREVIOUS ADMINS HAVE BEEN CHANGED TO BE STAFF"
  end

  desc "Update Travelers with an associated county"
  task associate_travelers_to_county: :environment do
    users = User.where("users.email ~* :ecolane", :ecolane => '\@ecolane_user\.com')
    puts "#{users.count} users have a fake email with a county"
  end

  desc "Update Travelers with an associated transit agency"
  task associate_travelers_to_agency: :environment do
    count = 0
    booking_profiles = UserBookingProfile.where.not(user_id:nil)
    ecolane_profiles = booking_profiles.where(booking_api: :ecolane)
    ecolane_profiles.each do |profile|
      transit = profile.service.agency
      user = profile.user
      TravelerTransitAgency.create(transportation_agency: transit, user: user)
      count += 1
    end
    puts "Associated #{count} travelers to transit agencies"
  end

  desc "Update Services with Penn DOT as the oversight agency"
  task associate_service_to_penn_dot: :environment do
    count = 0
    penn_dot = OversightAgency.find_by(name: "Penn DOT")
    # Only update Transit/ Paratransit services
    Service.where(type: %w[Transit Paratransit]).each do |service|
      ServiceOversightAgency.create(oversight_agency_id: penn_dot.id, service_id: service.id)
      count += 1
    end
    puts "#{count} services assigned to Penn DOT as their oversight agency"

  end

  desc "Associate staff with transit agencies"
  task associate_transit_staff: :environment do
    rabbit = TransportationAgency.find_or_create_by(name: "Rabbit")
    delaware = TransportationAgency.find_or_create_by(name: "Delaware County")
    count_rabbit = 0
    count_delaware = 0
    User.any_staff_admin_for_none.where("users.email ~* :delco", :delco => 'ctdelco\.org').each do |staff|
      staff.remove_role(:admin)
      staff.set_staff_role(delaware)
      count_delaware+=1
    end

    User.any_staff_admin_for_none.where("users.email ~* :rabbit", :rabbit => 'rabbittransit\.org').each do |staff|
      staff.remove_role(:admin)
      staff.set_staff_role(rabbit)
      count_rabbit+=1
    end
    puts "#{count_rabbit} staff assigned to Rabbit, #{count_delaware} staff assigned to Delaware"
  end


  desc "Update partner agencies so they're oversight agencies"
  task update_partner_agencies: :environment do
    names = []
    PartnerAgency.all.each do |agency|
      agency.update(type: "OversightAgency")
      agency.agency_type = AgencyType.find_by(name:"OversightAgency")
      names.push agency.name
    end
    puts "#{names.to_s} Partner agencies have been updated to oversight agencies"
  end

  desc "Add agency type to existing agencies"
  task add_agency_type: :environment do
    %w[PartnerAgency OversightAgency TransportationAgency].each do |type|
      AgencyType.find_or_create_by(name: type)
    end
  end

  desc "Associate agencies with agency_type"
  task associate_agency_type: :environment do
    count = 0
    Agency.all.each do |ag|
      ag.update(agency_type_id:AgencyType.find_by(name: ag.type).id)
      count += 1
    end
    puts "#{count} Agencies have been updated to use the AgencyType table"
  end

  desc "Create Penn DOT, and assign all transit agencies/ staff to Penn DOT"
  task create_and_assign_to_penn_dot:  [:add_penn_dot, :assign_agency_to_penn_dot,:assign_staff_to_penn_dot]

  desc "Associate Travelers to respective tables"
  task associate_travelers_to_tables:  [:associate_travelers_to_county, :associate_travelers_to_agency]

  desc "Do all but update partner agencies for QA"
  task all_qa: [:add_admin, :update_default_admin, :seed_unaffiliated_users,:seed_transportation_users,
        :seed_oversight_agency,:add_agency_type ,:create_and_assign_to_penn_dot,
        :associate_travelers_to_tables,
        :associate_service_to_penn_dot, :associate_transit_staff, :associate_agency_type]
  desc "Do all but update partner agencies for production"
  task all_prod: [:add_admin, :update_default_admin,
        :create_and_assign_to_penn_dot,:associate_travelers_to_county,
        :associate_travelers_to_tables,
        :associate_transit_staff, :associate_agency_type]
end
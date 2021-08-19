
namespace :agency_restriction do
  desc "Add admin role to agencies"
  task add_admin: :environment do
    Agency.all.each do |agency|
      Role.where(name: "admin", resource_id: agency.id, resource_type: agency.class.name).first_or_create
    end
  end
end
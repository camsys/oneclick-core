# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

## Create a default Superuser
superuser = User.where(email: '1-click@camsys.com').first_or_create do |user|
  user.password = 'welcome1'
  user.password_confirmation = 'welcome1'
  user.add_role(:superuser)
  puts 'Creating Default Superuser (Change these settings)'
  puts 'email: ' + user.email
  puts 'password: '+ 'welcome1'
end

# Initialize OTP url config
Config.find_or_create_by(key: "open_trip_planner")

# Set guest user email domain if not already set
guest_user_email_domain = Config.find_or_create_by(key: "guest_user_email_domain")
guest_user_email_domain.update_attributes(value: "example.com") unless guest_user_email_domain.value

## Add Translations
Rake::Task['simple_translation_engine:update'].invoke

# Initialize maximum booking notice config
Config.find_or_create_by(key: "maximun_booking_notice") do |config|
  config.value = 30
end

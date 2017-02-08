# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

## Create a default Admin User
admin = User.where(email: 'admin@oneclick.com').first_or_create do |user|
  user.password = 'welcome1'
  user.password_confirmation = 'welcome1'
  user.add_role :admin
  puts 'Creating Default Admin User (Change these settings)'
  puts 'email: ' + user.email
  puts 'password: '+ 'welcome1'
end


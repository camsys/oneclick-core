# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever


set :output, "/home/ubuntu/oneclick-core/log/cron_log.log"

# Times are UTC
every 1.day, at: '7:00 am' do
  rake 'scheduled:daily'
end

every 1.day, at: '5:00 am' do
  rake 'ecolane:update_pois'
end


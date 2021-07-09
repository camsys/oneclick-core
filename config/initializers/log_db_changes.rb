if ENV['RAILS_LOG_TO_STDOUT']
  ActiveSupport::Notifications
    .subscribe("sql.active_record") do |name, start, finish, id, payload|
    if /^(CREATE[[:blank:]]TABLE|ALTER[[:blank:]]TABLE|DROP[[:blank:]]TABLE)/i.match(payload[:sql])
      json = {
        data_access_type: 'PHI_MODIFICATION',
        **payload,
        timestamp: Time.now,
      }
      Rails.application.config.logger.info(JSON::dump(json))
    end
  end
end

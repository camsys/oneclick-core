module AdminHelpers

  def get_admin_pages
    urls = Rails.application.routes.url_helpers

    @admin_pages = [
      { label: "Accommodations",  url: urls.admin_accommodations_path,  show: can?(:read, Accommodation) },
      { label: "Alerts",          url: urls.admin_alerts_path,          show: can?(:read, Alert) },
      { label: "Agencies",        url: urls.admin_agencies_path,        show: can?(:read, Agency) },
      { label: "Configuration",   url: urls.admin_configs_path,         show: can?(:read, Config) },
      { label: "Feedback",        url: urls.admin_feedbacks_path,       show: can?(:read, Feedback) },
      { label: "Eligibilities",   url: urls.admin_eligibilities_path,   show: can?(:read, Eligibility) },
      { label: "Geography",       url: urls.admin_geographies_path,     show: can?(:read, GeographyRecord) },
      { label: "Landmarks",       url: urls.admin_landmarks_path,       show: can?(:read, Landmark) },
      { label: "Purposes",        url: urls.admin_purposes_path,        show: can?(:read, Purpose) },
      { label: "Reports",         url: urls.admin_reports_path,         show: can?(:read, :report) },
      { label: "Services",        url: urls.admin_services_path,        show: can?(:read, Service) },
      { label: "Staff",           url: urls.staff_admin_users_path,           show: can?(:read, User) },
      { label: "Translations",    url: simple_translation_engine.translations_path, show: can?(:read, Translation) },
      { label: "Travelers",       url: urls.travelers_admin_users_path, show: can?(:read, User) },
      { label: "My Agency",
        url: current_user.staff_agency.present? ? urls.admin_agency_path(current_user.staff_agency.try(:id)) : "",
        show: current_user.staff_agency.present? }
    ].select {|page| page[:show] }
    .sort_by { |page| page[:label] }
  end

end

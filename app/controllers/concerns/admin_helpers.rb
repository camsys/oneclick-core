module AdminHelpers
  
  def get_admin_pages
    urls = Rails.application.routes.url_helpers
    
    @admin_pages = [
      { label: "Accommodations",  url: urls.admin_accommodations_path,  can: can?(:read, Accommodation) },
      { label: "Agencies",        url: urls.admin_agencies_path,        can: can?(:read, Agency) },
      { label: "Configuration",   url: urls.admin_configs_path,         can: can?(:read, Config) },
      { label: "Feedback",        url: urls.admin_feedbacks_path,       can: can?(:read, Feedback) },
      { label: "Eligibilities",   url: urls.admin_eligibilities_path,   can: can?(:read, Eligibility) },
      { label: "Geography",       url: urls.admin_geographies_path,     can: can?(:read, GeographyRecord) },
      { label: "Landmarks",       url: urls.admin_landmarks_path,       can: can?(:read, Landmark) },
      { label: "Purposes",        url: urls.admin_purposes_path,        can: can?(:read, Purpose) },
      { label: "Reports",         url: urls.admin_reports_path,         can: can?(:read, :report) },
      { label: "Services",        url: urls.admin_services_path,        can: can?(:read, Service) },
      { label: "Staff",           url: urls.admin_users_path,           can: can?(:read, User) },
      { label: "Translations",    url: simple_translation_engine.translations_path, can: can?(:read, Translation) }
    ].select {|page| page[:can] }
    .sort_by { |page| page[:label] }
  end
  
end

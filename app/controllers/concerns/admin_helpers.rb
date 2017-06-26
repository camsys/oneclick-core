module AdminHelpers
  
  def get_admin_pages
    urls = Rails.application.routes.url_helpers
    
    @admin_pages = [
      { label: "Accommodations", url: urls.admin_accommodations_path },
      { label: "Agencies", url: urls.admin_agencies_path },
      { label: "Configuration", url: urls.admin_configs_path },
      { label: "Feedback", url: urls.admin_feedbacks_path },
      { label: "Eligibilities", url: urls.admin_eligibilities_path },
      { label: "Geography", url: urls.admin_geographies_path },
      { label: "Landmarks", url: urls.admin_landmarks_path },
      { label: "Purposes", url: urls.admin_purposes_path },
      { label: "Reports", url: urls.admin_reports_path },
      { label: "Services", url: urls.admin_services_path },
      { label: "Staff", url: urls.admin_users_path },
      { label: "Translations", url: simple_translation_engine.translations_path }
    ].sort_by { |page| page[:label] }.freeze
  end
  
end

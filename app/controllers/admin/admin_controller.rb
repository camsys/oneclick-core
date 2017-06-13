class Admin::AdminController < ApplicationController

  include Rails.application.routes.url_helpers

  before_action :confirm_admin
  before_action :get_admin_pages

  def index
  end
  
  private
  
  def get_admin_pages
    @admin_pages = [
      { label: "Accommodations", url: admin_accommodations_path },
      { label: "Configuration", url: admin_configs_path },
      { label: "Feedback", url: admin_feedbacks_path },
      { label: "Eligibilities", url: admin_eligibilities_path },
      { label: "Geography", url: admin_geographies_path },
      { label: "Landmarks", url: admin_landmarks_path },
      { label: "Purposes", url: admin_purposes_path },
      { label: "Reports", url: admin_reports_path },
      { label: "Services", url: admin_services_path },
      { label: "Staff", url: admin_users_path },
      { label: "Translations", url: simple_translation_engine.translations_path }
    ].sort_by { |page| page[:label] }
  end

end

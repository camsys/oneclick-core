# Inject auth functionality into TranslationsController
module TranslationsControllerExtensions
  extend ActiveSupport::Concern

  included do
    include AdminHelpers

    before_action :confirm_admin
    before_action :get_admin_pages
  end

end

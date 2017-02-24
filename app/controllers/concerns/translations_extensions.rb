module TranslationsExtensions
  extend ActiveSupport::Concern

  included do

    before_action :confirm_admin

  end

end
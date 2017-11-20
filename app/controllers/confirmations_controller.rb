class ConfirmationsController < Devise::ConfirmationsController
  private
  def after_confirmation_path_for(resource_name, resource)
    if resource.roles.blank?
      return Config.ui_url
    else 
      return root_url
    end 
  end
end
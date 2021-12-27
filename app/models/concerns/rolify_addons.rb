# Rolify add on based on the linked gist and the parent issue:
# https://github.com/RolifyCommunity/rolify/issues/362
# https://gist.github.com/jamesmarkcook/0435bb68a3840c89bda4a0e7da81cb24
module RolifyAddons
  extend ActiveSupport::Concern
  # NOTE: ALL OF THESE SCOPES REQUIRE THE RECORD(S) TO BE PASSED IN AS METHOD PARAMS
  included do
    scope :with_role_for_instance, ->(role_name, instance) do
      resource_name = instance.class.name

      joins(:roles).where(roles: {
        name: role_name.to_s,
        resource_type: resource_name,
        resource_id: instance&.id
      })
    end

    scope :with_roles_for_instance, -> (role_names, instance) do
      joins(:roles).where(roles: {
        name: role_names.map{|role| role.to_s},
        resource_id: instance&.id
      })
    end

    scope :with_role_for_instances, -> (role_name, instances) do
      joins(:roles).where(roles: {
        name: role_name.to_s,
        resource_id: instances&.pluck(:id)
      })
    end

    scope :with_roles_for_instances, -> (role_names, instances) do
      joins(:roles).where(roles: {
        name: role_names.map{|role| role.to_s},
        resource_id: instances&.pluck(:id)
      })
    end

  end
end
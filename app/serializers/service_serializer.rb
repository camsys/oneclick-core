class ServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :url, :email, :phone
end

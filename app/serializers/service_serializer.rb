class ServiceSerializer < ActiveModel::Serializer

  attributes :id, :name, :type, :url, :email, :phone

  def phone
  	object.formatted_phone
  end 

end

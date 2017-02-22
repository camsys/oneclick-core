class Service < ApplicationRecord

  validates_presence_of :name, :type
  mount_uploader :logo, LogoUploader

  def self.types
    ['Transit', 'Paratransit', 'Taxi']
  end

end

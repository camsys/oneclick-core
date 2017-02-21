class Service < ApplicationRecord

  validates :name, presence: true
  mount_uploader :logo, LogoUploader

  def self.types
    ['Transit', 'Paratransit', 'Taxi']
  end

end

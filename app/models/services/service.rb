class Service < ApplicationRecord

  validates :name, presence: true

  def self.types
    ['Transit', 'Paratransit', 'Taxi']
  end

end

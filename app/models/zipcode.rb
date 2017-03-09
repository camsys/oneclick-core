class Zipcode < ApplicationRecord

  validates_presence_of :name

  def to_s
    name
  end

end

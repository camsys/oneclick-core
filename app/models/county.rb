class County < ApplicationRecord

  validates_presence_of :name, :state

  def to_s
    "#{name}, #{state}"
  end

end

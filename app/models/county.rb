class County < ApplicationRecord

  def to_s
    "#{name}, #{state}"
  end

end

class Config < ApplicationRecord

  serialize :types

  validates :key, presence: true
  validates :key, uniqueness: true

  # Returns the value of a setting when you say Setting.<key>
  def self.method_missing(key, *args, &blk)

    config = Config.find_by(key: key)
    if config.nil?
      return nil
    else
      return config.value
    end

  end

end

class Config < ApplicationRecord

  serialize :value

  validates :key, presence: true
  validates :key, uniqueness: true

  # Returns the value of a setting when you say Config.<key>
  def self.method_missing(key, *args, &blk)

    config = Config.find_by(key: key)
    if config.nil?
      return Rails.application.config.send(key) if Rails.application.config.respond_to?(key)
      return nil
    else
      return config.value
    end

  end

end

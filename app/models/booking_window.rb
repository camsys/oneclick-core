class BookingWindow < ApplicationRecord
  belongs_to :agency
  has_many :travel_patterns, dependent: :restrict_with_error

  validates_presence_of :agency, :name, :minimum_days_notice, :maximum_days_notice, :minimum_notice_cutoff_hour
  validates :minimum_days_notice, numericality: { less_than_or_equal_to: :maximum_days_notice }
  validate :valid_booking_notice

  scope :for_date, -> (date) do
    notice = (date - Date.current).to_i
    where(
      arel_table[:minimum_days_notice].eq(notice)
                                      .and(arel_table[:minimum_notice_cutoff_hour].gt(Time.now.hour))
                                      .or(arel_table[:minimum_days_notice].lt(notice))
    ).where(
      arel_table[:maximum_days_notice].gteq(notice)
    )
  end

  def earliest_booking
    present = DateTime.now
    additional_notice = minimum_notice_cutoff_hour <= present.hour ? 1 : 0
    (present + (minimum_days_notice + additional_notice).days).beginning_of_day
  end

  def latest_booking
    present = DateTime.now
    (present + maximum_days_notice.days).end_of_day
  end

  private

  def valid_booking_notice
    max_notice = Config.maximum_booking_notice || 30
    [:minimum_days_notice, :maximum_days_notice].each do |attribute|
      if self[attribute].present?
        self.errors.add(attribute, "must be less than or equal to #{max_notice}") unless self[attribute] <= max_notice
        self.errors.add(attribute, "must be greater than or equal to 1") unless self[attribute] >= 1
      end
    end
  end
end

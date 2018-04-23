class Feedback < ApplicationRecord
  
  DEFAULT_SUBJECT = "General"
    
  ### INCLUDES & ASSOCIATIONS ###
  
  belongs_to :feedbackable, polymorphic: true
  belongs_to :user
  include Commentable # has_many :comments
  include Contactable
  has_one :acknowledgement_comment, class_name: "Comment", as: :commentable
  accepts_nested_attributes_for :acknowledgement_comment
  write_to_csv with: Admin::FeedbackReportCSVWriter
  
  ### SCOPES ###
  
  scope :general, -> { where(feedbackable_id: nil)}
  scope :newest_first, -> { order(created_at: :desc) }
  scope :pending, -> { where(acknowledged: false).newest_first }
  scope :acknowledged, -> { where(acknowledged: true).newest_first }
  scope :about, -> (feedbackable) { where(feedbackable: feedbackable) }
  scope :service, -> { where(feedbackable_type: Service) }

  #TODO: MAKE DEFAULT FEEDBACK TIME A CONFIG
  scope :needs_reminding, -> { where('acknowledged = ? and created_at < ?', false, Time.now - (Config.feedback_overdue_days || 5).days).newest_first }
    
  # Return trips before or after a given date and time
  scope :from_datetime, -> (datetime) { datetime ? where('feedbacks.created_at >= ?', datetime) : all }
  scope :to_datetime, -> (datetime) { datetime ? where('feedbacks.created_at <= ?', datetime) : all }

  # Rounds to beginning or end of day.
  scope :from_date, -> (date) { date ? from_datetime(date.in_time_zone.beginning_of_day) : all }
  scope :to_date, -> (date) { date ? to_datetime(date.in_time_zone.end_of_day) : all }

  ### VALIDATIONS ###
  
  validates :rating, numericality: { only_integer: true, 
                                     greater_than_or_equal_to: 0, 
                                     less_than_or_equal_to: 5,
                                     allow_nil: true }
  validates_comment_commenter_presence
  validates :feedbackable_type, 
      inclusion: { in: Feedbackable.feedbackables }, 
      allow_nil: true
  validates :feedbackable_id, 
      presence: true, 
      unless: Proc.new{ |f| f.feedbackable_type.nil? }
  contact_fields email: :email, phone: :phone
  
  ### METHODS ###
  
  # If no feedbackable is present, what is the feedback about?
  def default_subject
    DEFAULT_SUBJECT
  end
  
  # Returns a description of what the feedback is about
  def subject
    feedbackable.try(:to_s) || default_subject
  end
  
  # Alias for acknowledged boolean attribute
  def acknowledged?
    acknowledged
  end
  
  # Return's the contact email or phone
  def contact
    [contact_email, contact_phone].compact.join(', ')
    # {email: contact_email, phone: contact_phone}.compact.map do |k,v|
    #   "#{k}: #{v}"
    # end.join(",  ")
  end
  
  # Returns the feedback's email, or the associated user's email
  def contact_email
    email || user.try(:email)
  end
  
  # Returns the feedback's phone, or the associated user's phone
  def contact_phone
    phone || user.try(:phone)
  end

  # Aggregate Results for Reporting
  def self.aggregated_csv from, to 
    the_data = "service_id,service_name,average_rating,total_ratings\n"
    service_hash = {}
    @feedback = Feedback.from_date(from).to_date(to)
    @feedback.each do |feedback|
      
      next unless feedback.feedbackable_id
      next if feedback.rating.nil?

      # Get the Service (Transportation or 211)
      if feedback.feedbackable_type == 'Service'
         service = Service.find_by(id: feedback.feedbackable_id)
         next if service.nil?
         name = service.name
         id = "transportation_#{service.id}"
      elsif feedback.feedbackable_type == 'OneclickRefernet::Service'
         service = OneclickRefernet::Service.find_by(id: feedback.feedbackable_id)
         next if service.nil?
         name = service.agency_name
         id = "refernet_#{service.id}"
      end

      service_stats = service_hash[id] || {id: id, service_name: name, average_rating: nil, total_ratings: 0, cumulative_rating: 0}
      service_stats[:total_ratings] += 1 
      service_stats[:cumulative_rating] += feedback.rating
      service_stats[:average_rating] = service_stats[:cumulative_rating].to_f/service_stats[:total_ratings].to_f
      service_hash[id] = service_stats
    end

    service_hash.each do |key, service|
      the_data += "#{service[:id]},#{service[:service_name]},#{service[:average_rating]},#{service[:total_ratings]}\n"
    end

    return the_data

  end
  
  
end

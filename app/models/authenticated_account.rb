class AuthenticatedAccount < ApplicationRecord
  ACCOUNT_TYPES = ["BUSINESS_PARTNER", "CWOPA", "CITIZEN"]

  belongs_to :user
  has_many :account_identities, dependent: :destroy

  # For now Users to AuthenticatedAccounts is a has_one relationship
  # Therefore, the user_id should be unique 
  validates_uniqueness_of :subject_uuid, :user_id
  validates_presence_of :subject_uuid
  validates :account_type, 
            inclusion: { in: ACCOUNT_TYPES, message: "%{value} is not a valid account type" }
  validates :email, 
            format: { with: /\A(.+)@(.+)\z/, message: "Email invalid"  }, 
            length: { minimum: 4, maximum: 254 }
  
  def self.get_type_from_userDN(user_dn)
    dns = user_dn.split(',').map do |dn|
      dn = dn.split("=")
      { key: dn[0].strip, value: dn[1].strip }
    end

    is_business_partner = dns.detect do |dn|
      dn[:key] == "OU" && dn[:value] == "Business Entities"
    end

    is_cwopa = dns.detect do |dn|
      dn[:key] == "OU" && dn[:value] == "CWOPA"
    end

    return "BUSINESS_PARTNER" if is_business_partner
    return "CWOPA" if is_cwopa
    return "CITIZEN"
  end
end
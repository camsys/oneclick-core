class AccountIdentity < ApplicationRecord
  belongs_to :authenticated_account
  validates_presence_of :authenticated_account, :identity, :provider
end
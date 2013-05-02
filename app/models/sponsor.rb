class Sponsor < ActiveRecord::Base
  include Extensions::Adminable

  attr_accessible :logo, :name, :url, :user_id, :user

  validates :user_id, presence: true
  validates :name, presence: true

  has_many :campaigns
  belongs_to :user
end

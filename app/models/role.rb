class Role < ActiveRecord::Base
  has_many :campaign_finances, foreign_key: "role_id"
end

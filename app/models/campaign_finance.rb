class CampaignFinance < ActiveRecord::Base
  belongs_to :role, -> { select("id, nama_lengkap") }, foreign_key: :role_id  
end

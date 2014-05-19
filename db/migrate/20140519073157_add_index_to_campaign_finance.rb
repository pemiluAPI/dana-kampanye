class AddIndexToCampaignFinance < ActiveRecord::Migration
  def change
    add_index :campaign_finances, :calon_id
    add_index :campaign_finances, :nama
  end
end

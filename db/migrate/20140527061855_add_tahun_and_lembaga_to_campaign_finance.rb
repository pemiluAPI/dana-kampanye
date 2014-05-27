class AddTahunAndLembagaToCampaignFinance < ActiveRecord::Migration
  def change
    change_table :campaign_finances do |t|
      t.string :lembaga
      t.integer :tahun
    end
  end
end

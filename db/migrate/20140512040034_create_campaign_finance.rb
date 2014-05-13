class CreateCampaignFinance < ActiveRecord::Migration
  def change
    create_table :campaign_finances do |t|
      t.string :periode
      t.integer :partai_id
      t.integer :role_id      
      t.string :nama
      t.string :calon_id
      t.string :mata_uang
      t.string :uang
      t.string :nilai_barang
      t.string :unit_barang
      t.string :nilai_jasa
      t.string :bentuk_jasa
      t.string :jumlah
      t.string :keterangan
    end
  end
end

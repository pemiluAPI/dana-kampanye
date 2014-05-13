class CreateRole < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :nama_pendek
      t.string :nama_lengkap      
    end
  end
end
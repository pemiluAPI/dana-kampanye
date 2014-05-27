# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140527061855) do

  create_table "campaign_finances", force: true do |t|
    t.string  "periode"
    t.integer "partai_id"
    t.string  "nama_partai"
    t.integer "role_id"
    t.string  "nama"
    t.string  "calon_id"
    t.string  "mata_uang"
    t.string  "uang"
    t.string  "nilai_barang"
    t.string  "unit_barang"
    t.string  "nilai_jasa"
    t.string  "bentuk_jasa"
    t.string  "jumlah"
    t.string  "keterangan"
    t.string  "lembaga"
    t.integer "tahun"
  end

  add_index "campaign_finances", ["calon_id"], name: "index_campaign_finances_on_calon_id", using: :btree
  add_index "campaign_finances", ["nama"], name: "index_campaign_finances_on_nama", using: :btree

  create_table "roles", force: true do |t|
    t.string "nama_pendek"
    t.string "nama_lengkap"
  end

end

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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120717021515) do

  create_table "cities", :force => true do |t|
    t.integer  "player_id"
    t.integer  "upper_left_x"
    t.integer  "upper_left_y"
    t.string   "name"
    t.boolean  "capital"
    t.decimal  "tax_rate",                 :precision => 8, :scale => 2
    t.integer  "population"
    t.integer  "glod"
    t.integer  "food"
    t.datetime "last_updated_resource_at"
    t.integer  "lock_version"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  create_table "events", :force => true do |t|
    t.integer  "city_id"
    t.integer  "event_type"
    t.datetime "ends_at"
    t.text     "content"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "troops", :force => true do |t|
    t.integer  "city_id"
    t.integer  "soldier_type"
    t.integer  "number"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

end

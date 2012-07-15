# -*- coding: utf-8 -*-
class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.integer :player_id
      t.integer :upper_left_x 
      t.integer :upper_left_y
      t.string   :name
      t.boolean :capital , :deafult => :false  # 是否是首都
      t.decimal :tax_rate , :precision => 8, :scale => 2
      t.integer :population
      t.integer :glod
      t.integer :food
      
      t.timestamp :last_updated_resource_at #最后一次更新 资源的时间 
      t.integer :lock_version
      t.timestamps
    end
  end
end

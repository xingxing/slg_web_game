# -*- coding: utf-8 -*-
class CreateTroops < ActiveRecord::Migration
  def change
    create_table :troops do |t|
      t.integer :city_id      
      t.integer :soldier_type # 兵种
      t.integer :number       # 人数  
      
      t.timestamps
    end
  end
end

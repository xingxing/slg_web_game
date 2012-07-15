# -*- coding: utf-8 -*-
class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :city_id        # 事件发生城市
      t.integer :event_type  # 事件的类型
      t.time    :ends_at      # 事件的结束时间 
      t.text    :content      # 事件的相关数据
      
      t.timestamps
    end
  end
end

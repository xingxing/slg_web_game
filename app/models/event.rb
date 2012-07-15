# -*- coding: utf-8 -*-
class Event < ActiveRecord::Base
  belongs_to :city
  
  # 事件类型
  Type = { :tax => 1 }

  class << self
    # 计划收税
    # @param [Fixnum] 城市ID
    def plans_to_tax city_id
      event = self.create(
                       :city_id => city_id ,
                       :ends_at =>  1.hour.since(DateTime.now),
                       :event_type => Type[:tax]
                       )
    end
  end
end

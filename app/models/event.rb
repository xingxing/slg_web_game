# -*- coding: utf-8 -*-
class Event < ActiveRecord::Base
  belongs_to :city
  
  # 事件类型
  Type = { :tax => 1 }

  class << self
    # 计划征税
    # @param [Fixnum] 城市ID
    def plans_to_tax city_id
      event = self.create(
                          :city_id => city_id ,
                          :ends_at =>  1.hour.since(DateTime.now),
                          :event_type => Type[:tax]
                          )
      event
    end
  end

  # 运行事件
  def ends
    method_name = Type.invert[self.event_type]
    self.send(method_name)
    self.destroy
  end

  # TODO: 征税
  def tax
    
  end
end

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
    city = self.city
    City.transaction do
      city.update_attributes :glod => (city.population * city.tax_rate).round
      if city.population < city.tax_rate * 1000
        city.update_attributes :population => city.population+min_1_and_max_1000(city.population*0.05)
      elsif city.population > city.tax_rate * 1000
        city.update_attributes :population => city.population-min_1_and_max_1000(city.population*0.05)        end
    end
  end

  private 
  
  # 最少是1最大是1000 
  def min_1_and_max_1000 num
    if num >= 1000
      1000
    else
     [1,num].max.to_i
    end
  end
end

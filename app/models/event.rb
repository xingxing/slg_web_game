# -*- coding: utf-8 -*-
class Event < ActiveRecord::Base
  
  belongs_to :city
  
  validate :only_5_train_plans_one_city

  # 事件类型
  Type = {
    :tax => 1,   # 征税
    :train => 2, # 训练部队
    :build => 3  # 建造单位(房屋或者士兵)
  }

  class << self
    # 计划征税
    # @param [Fixnum] 城市ID
    def plans_to_tax city_id
      self.create(city_id: city_id ,
                  ends_at: 1.hour.since(DateTime.now),
                  event_type: Type[:tax])
    end

    # 计划训练一批士兵
    # @param [Fixnum] 城市ID
    # @param [Symbol] 兵种
    # @param [Fixnum] 训练人数
    # @param [Event]  训练士兵的事件
    def plans_to_train city_id,soldier_type,number
      city = City.find(city_id)
      fee  = Troop::Commission[soldier_type] * number
      # 子事件 id 
      sub_event_ids = []

      if city.glod >= fee and city.population >= number  
        begin
          City.transaction do
            Event.transaction do 
              number.times do |index|
                sub_event = self.plans_to_build_soldier city_id,soldier_type,index+1
                sub_event_ids << sub_event.id 
              end

              city.update_resource(population: city.population - number ,
                                   glod: city.glod - fee)

              train = Event.new(city_id: city_id,
                                event_type: Type[:train],
                                content: Oj.dump({ sub_event_ids: sub_event_ids,
                                                   soldier_type: soldier_type,
                                                   number: number}))
              train.ends_at = train.sub_events.last.ends_at
              train.save!
              train
            end
          end
        rescue ActiveRecord::RecordInvalid => invalid
          nil
        end
      end
    end

    # 计划建造士兵
    # @param [Fixnum] 城市ID
    # @param [Symbol] 兵种
    # @param [Fixnum] 建造队列中的索引(从1开始)
    def plans_to_build_soldier city_id,soldier_type,queue_index=1
      self.create(city_id: city_id,
                  event_type: Type[:build],
                  ends_at: (Troop::TrainTime[soldier_type] * queue_index).minutes.since )
    end
  end

  # 完成事件
  def ends
    method_name = Type.invert[self.event_type]
    self.send(method_name)
    self.destroy
  end

  # 征税
  def tax
    city = self.city
    City.transaction do
      if city.population < city.tax_rate * 1000
        city.update_resource(glod: (city.population * city.tax_rate).round , 
                             population: city.population+min_1_and_max_1000(city.population*0.05))
      elsif city.population > city.tax_rate * 1000
        city.update_resource(glod: (city.population * city.tax_rate).round ,
                             population: city.population-min_1_and_max_1000(city.population*0.05))
      end
    end
    Event.plans_to_tax city.id
  end

  # TODO: 建造单位
  def build
    
  end

  # 训练一批结束
  def train
    # 什么也不用做
  end

  # 事件数据
  # @return[Hash]
  def event_content
    unless content.blank?
      Oj.load content
    else
      {}
    end
  end

  # 子事件
  # @return[Array<Event>] 子事件集合
  def sub_events
    unless event_content[:sub_event_ids].blank?
      Event.where(id: event_content[:sub_event_ids]).order("ends_at DESC").all
    else
      []
    end
  end

  # TODO: 取消事件计划
  def cancel
  end

  


  private 
  
  # 最少是1最大是1000 
  def min_1_and_max_1000 num
    num >= 1000 ? 1000 : [1,num].max.to_i
  end
  
  # 每座城市同时可以有最多至5批士兵等待接受训练
  def only_5_train_plans_one_city
    errors.add(:city_id,"每座城市同时可以有最多至5批士兵等待接受训练") if Event.where(city_id: self.city_id,event_type: Type[:train]).count >= 5 and self.event_type == Type[:train] 
  end
end

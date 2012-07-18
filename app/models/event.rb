# -*- coding: utf-8 -*-
class Event < ActiveRecord::Base
  
  belongs_to :city
  belongs_to :target_city,:class_name => "City",:foreign_key => :target_city_id

  validate :only_5_train_plans_one_city
  validate :only_5_troops_outside

  # 事件类型
  Type = {
    :tax => 1,   # 征税
    :train => 2, # 训练部队
    :build => 3,  # 建造单位(房屋或者士兵)
    :send_troops => 4, # 出兵
    :troops_back => 5  # 部队回城
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
      # 子事件id集合
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
    # @param [Fixnum] 建造队列中的位置(从1开始)
    def plans_to_build_soldier city_id,soldier_type,queue_index=1
      self.create( city_id: city_id,
                   event_type: Type[:build],
                   content: Oj.dump({ klass: 'Troop' , attrs: {city_id: city_id,soldier_type: Troop::SoldierTypes[soldier_type]}}) ,
                   ends_at: (Troop::TrainTime[soldier_type] * queue_index).minutes.since )
    end

    # 计划出兵
    # @param [Fixnum] 出兵城市ID
    # @param [Fixnum] 目标城市ID
    # @param [Hash] 部署表 e.g. {pikemen: 5 ,cavalry: 3}
    # @return [Event] 
    def plans_to_send_troops city_id,target_city_id,array
      city,target_city = City.find(city_id),City.find(target_city_id)

      if city.can_send_troops? array
        begin
           City.transaction do
            Event.transaction do 
              distance = city.distance_from(target_city)
              mins = (distance / Troop.speed(array)).round

              # 无需更新城市资源，因为 出战部队一样要消耗粮食
              Troop.war(city,array)

              self.create!(city_id: city.id,
                           target_city_id: target_city.id,
                           event_type: Type[:send_troops],
                           ends_at: mins.minutes.since,
                           content: Oj.dump({array: array,:distance => distance}))
            end
          end
        rescue ActiveRecord::RecordInvalid => invalid
          nil
        end
      end
    end

    
    # 计划回城
    # @param [Event] 出兵计划事件
    # @param [Hash]  幸存士兵
    # @return [Event] 回城计划
    def plans_to_troops_back send_troops_event , array
      city,target_city = send_troops_event.target_city,send_troops_event.city
      distance = send_troops_event.event_content[:distance]
      mins = (distance / Troop.speed(array)).round

      self.create( :city => city,
                   :target_city => target_city,
                   :ends_at => mins.minutes.since,
                   :content => Oj.dump({array: array}))
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

    # 如果发生粮食危机
    if city.food.zero?
      city.troops.each do |troop|
        troop.update_attributes :number => (troop.number * (1-0.1)).round
      end
    end

    Event.plans_to_tax city.id
  end

  # 建造单位
  def build
    Kernel.const_get(self.event_content[:klass]).build(self.event_content[:attrs]) unless self.event_content[:klass].blank? 
  end
  
  # 取消一批训练
  def cancel_train
    city = self.city
    city.update_resource(:population => (city.population + self.sub_events.map{|v| v.destroy }.size))
  end

  # 训练一批结束
  def train
    # 什么也不用做
  end

  # 出兵攻打城市
  # @return[Event] 回城计划
  def send_troops
    target_city,city = self.target_city,self.city
    # 更新阵亡数字数量前更新双方资源
    target_city.update_resource
    city.update_resource

    # 阵亡
    target_city.troops.each do |troop| 
      troop.update_attributes :number => troop.number - rand(troop.number)
    end

    back_array = {}

    self.event_content[:array].each do |soldier_type,number|
      back_number = number - rand(number)
      back_array[soldier_type] = back_number if back_number > 0 
    end

    Event.plans_to_troops_back self,back_array
  end

  # 回城
  def troops_back
    back_array = self.event_content[:array]

    self.target_city.troops.each do |troop|
      soldier_type = Troop::SoldierTypes.invert[troop.soldier_type]
      troop.update_attributes :number => troop.number + back_array[soldier_type]
    end
  end

  # 事件数据
  # @return[Hash]
  def event_content
    content.blank? ? {} : Oj.load(content)
  end

  # 子事件
  # @return[Array<Event>] 子事件集合
  def sub_events
    event_content[:sub_event_ids].blank? ? [] : Event.where(id: event_content[:sub_event_ids]).order("ends_at ASC").all
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

  # 每个城市最多有5支军队 在出征或回城路上
  def only_5_troops_outside
    errors.add(:city_id,"每个城市最多有5支军队 在出征或回城路上") if Event.where(["(city_id = ? and event_type = ?) OR (target_city_id = ? and event_type= ?)",
                                                                                  self.city_id,
                                                                                  Type[:send_troops],
                                                                                  self.city_id,
                                                                                  Type[:troops_back]]).count >= 5 and self.event_type == Type[:send_troops]   
  end
end

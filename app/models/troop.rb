# -*- coding: utf-8 -*-
class Troop < ActiveRecord::Base

  belongs_to :city
  
  # 兵种
  SoldierTypes = { pikemen: 1, archer: 2 ,cavalry: 3 } 
  # 每兵种一人的训练时间(m)
  TrainTime = { pikemen: 3 , archer: 12 , cavalry: 50 } 
  # 一次性支付的佣金
  Commission = { pikemen: 1 , archer: 3 , cavalry: 10 } 
  # 士兵每小时消耗的口粮
  Rations = { pikemen: 10 , archer: 13 , cavalry: 30 } 
  # 各兵种的行军速度(/m)
  Speed = { pikemen: 1.5 , archer: 2 , cavalry: 10 }

  validates :soldier_type, :uniqueness => { :scope => :city_id,
    :message => "每个兵种在一个城市只能有一只部队" }

  class << self
    # 创建 士兵
    def build attrs={}
      city = City.find(attrs[:city_id])
      if  troop = city.send("#{SoldierTypes.invert[attrs[:soldier_type]]}")
        troop.update_attributes :number => troop.number + 1
      else
        self.create(attrs.merge(:number => 1))
      end
      city.update_resource
    end

    # 从部署表中得到 军团的行军速度
    # @param [Hash]部署表
    def speed array
      Speed.sort_by{|_,speed| speed }.find{|map| array[map[0]] > 0 }[1]
    end
    
    # 根据部署表 减去城中戍卫军队的数量
    def war city,array
      array.each do |soldier_type,number|
        troop = city.send("#{soldier_type}")
        troop.update_attributes(:number => troop.number-number )
      end
    end
  end
end

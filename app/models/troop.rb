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
  Rations = {SoldierTypes[:pikemen] => 10 , SoldierTypes[:archer] => 13 , SoldierTypes[:cavalry] => 30 } 

  validates :soldier_type, :uniqueness => { :scope => :city_id,
    :message => "每个兵种在一个城市只能有一只部队" }

end

# -*- coding: utf-8 -*-
class City < ActiveRecord::Base

  validate :only_capital

  # 普通城市每小时产出1,000食物 
  AgriculturalOutputPerHour = 1000
  # 首都城市每小时产出10,000食物
  AgriculturalOutputPerHourOfTheCapital = 10000

  has_many :events 
  has_many :troops

  Troop::SoldierTypes.each do |soldier_type,code|
    has_one soldier_type,:class_name => "Troop",:conditions => ["troops.soldier_type = ?",code]

    delegate :number, :to => soldier_type,:prefix => soldier_type ,:allow_nil => true
  end

  class  << self 
    # 建立一座城市
    # @param [Fixnum] 玩家ID
    # @param [Fixnum] 城市的左上角x坐标
    # @param [Fixnum] 城市的左上角y坐标
    # @param [City] 新城
    def build player_id,x,y
      new_city = self.new(
                          :player_id => player_id,
                          :upper_left_x => x,
                          :upper_left_y => y,
                          :tax_rate  => 0.2 ,
                          :population => 100,
                          :glod =>  0,
                          :food =>  0
                          )
      if new_city.save!
        Event.plans_to_tax new_city.id
      end
      new_city
    end

    # 首都
    def capital_of player_id
      self.find_by_player_id_and_capital player_id,true
    end

    # 迁都
    def move_the_capital_to player_id,city_id
      self.transaction do
        capital = self.capital_of player_id
        capital_to_be = self.find_by_player_id_and_id player_id,city_id
        capital.update_resource
        capital_to_be.update_resource
        capital.update_attributes(:capital => false)
        capital_to_be.update_attributes(:capital => true)
      end
    end
  end  

  # 当前城市资源信息:食物、金子、人口
  # @return[Hash]  
  def current_resource_info  
    { population: self.population,
      glod: self.glod,
      food: self.current_food }
  end
  
  # TODO:查询 城市当前信息  出每一个兵种的士兵数量，以及目前训练的进展（如果有的话）、排队等待接受训练的士兵情况
  def current_info
    {tax_rate: self.tax_rate}.merge(self.current_resource_info)
  end

  # 当前食物数量
  # @return[Fixnum]
  def current_food
    food_increase + self.food
  end

  # 调节税率
  def adjust_tax_rate tax_rate
    self.update_attributes :tax_rate => tax_rate
  end

  # 更新资源
  def update_resource resource={}
    self.update_attributes self.current_resource_info.merge(resource)
    self.touch(:last_updated_resource_at)
  end

  private 

  # 检查 玩家唯一首都
  def only_capital
    errors.add(:capital,"每个玩家只能有一座首都") if City.where(player_id: self.player_id,capital: true ).count > 0 and self.capital
  end

  # 距离上次更新 的 食物增长
  # (当前时间 - 上一次更新时间)*每小时食物产量
  # @return[Fixnum]
  def food_increase
    agricultural_output_per_hour = self.capital ? AgriculturalOutputPerHourOfTheCapital : AgriculturalOutputPerHour
    last_updated_resource_time   = self.last_updated_resource_at || self.created_at
    ((Time.now - last_updated_resource_time) / 3600 * agricultural_output_per_hour).round
  end

  # TODO: 距离上次更新 的 食物消耗
  # (当前时间 - 上一次更新时间)*每小时食物消耗
  # @return[Fixnum]
  def food_expend
  end
end

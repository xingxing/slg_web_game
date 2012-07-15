# -*- coding: utf-8 -*-
class City < ActiveRecord::Base

  validate :only_capital

  # 普通城市每小时产出1,000食物 
  AgriculturalOutputPerHour = 1000
  # 首都城市每小时产出10,000食物
  AgriculturalOutputPerHourOfTheCapital = 10000

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
  end  

  # 当前城市信息:食物、金子、人口以及税率状况
  # @return[Hash]  
  def current_info  
    { population: self.population,
      tax_rate: self.tax_rate,
      glod: self.glod,
      food: self.current_food }
  end

  # 当前食物数量
  # @return[Fixnum]
  def current_food
    food_increase + self.food
  end

  # 更新资源(金子、人口、食物)
  # @param [Hash]
  def update_resource attrs
    self.update_attributes attrs
    self.touch(:last_updated_resource_at)
  end

  # 调节税率
  def adjust_tax_rate tax_rate
    self.update_attributes :tax_rate => tax_rate
  end

  # TODO: 迁都
  def move_the_capital
  end

  private 

  # 检查 玩家唯一首都
  def only_capital
    errors.add(:capital, ("每个玩家只能有一座首都")) if City.where(player_id: self.player_id,capital: true ).count > 0 and self.capital
  end

  # 距离上次更新 的 食物增长
  # (当前时间 - 上一次更新时间)*每小时食物产量
  # @return[Fixnum]
  def food_increase
    agricultural_output_per_hour = self.capital ? AgriculturalOutputPerHourOfTheCapital : Agricultural_Output_Per_Hour
    last_updated_resource_time   = self.last_updated_resource_at || self.created_at
    ((Time.now - last_updated_resource_time) / 3600 * agricultural_output_per_hour).round
  end

end

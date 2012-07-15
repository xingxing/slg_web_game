# -*- coding: utf-8 -*-
require 'spec_helper'

describe City do
  describe "数据校验" do
    before do
      @beijing = FactoryGirl.create(:beijing)
    end

    it "每个玩家 只能有一座首都" do
      shanghai = FactoryGirl.build(:shanghai)
      shanghai.capital =  false
      shanghai.should be_valid
      shanghai.capital =  true
      shanghai.should_not be_valid
    end
  end

  describe "创建城市" do
    before do
      @new_city = City.build(1,rand(200),rand(200))
    end

    it "新的城市开始仅有100人口" do
      @new_city.population.should == 100
    end

    it "新的城市没有食物" do 
      @new_city.food.should == 0
    end

    it "新的城市没有金子" do
      @new_city.glod.should == 0
    end

    it "初始税率为20%" do
      @new_city.tax_rate.should == 0.2
    end

    it "自城市创建伊始即开始征税" do
      Event.should_receive(:plans_to_tax)
      City.build(1,rand(200),rand(200))
    end
  end

  describe "当前城市信息" do
    before do
      @beijing = FactoryGirl.create(:beijing)
    end

    it "城市人口" do
      @beijing.current_info[:population].should == 100
    end
    
    it "税率" do
      @beijing.current_info[:tax_rate].should == 0.2
    end

    it "金子数量" do
      @beijing.current_info[:glod].should == 0
    end

    describe "食物数量" do
      it "应该为 距离上次更新的食物增长+上次更新的食物产量" do
        now = Time.now
        hours = rand(10)
        @beijing.last_updated_resource_at = now.ago(3600*hours)
        @beijing.current_info[:food].should == 10000 * hours + @beijing.food
      end
    end
  end
end


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

  describe "当前城市资源信息" do
    before do
      @beijing = FactoryGirl.create(:beijing)
    end

    it "城市人口" do
      @beijing.current_resource_info[:population].should == 100
    end

    it "金子数量" do
      @beijing.current_resource_info[:glod].should == 0
    end

    describe "食物数量" do
      it "应该为 距离上次更新的食物增长+上次更新的食物产量-距离上次更新 的 食物消耗" do
        FactoryGirl.create(:pikemen,:city_id => @beijing.id)
        @beijing.last_updated_resource_at = 3.hours.ago
        @beijing.current_resource_info[:food].should == 10000 * 3 + @beijing.food - (10*60*10*3)
      end

      it "耗尽时，应为0(不会变成负数)" do
        FactoryGirl.create(:cavalry,:city_id => @beijing.id,:number => 1000 )
        @beijing.last_updated_resource_at = 1.hours.ago
        @beijing.current_resource_info[:food].should == 0
      end
    end
  end

  describe "调节税率" do
    it "应该 改变税率" do
      shanghai = FactoryGirl.build(:shanghai)
      shanghai.adjust_tax_rate(0.5)
      shanghai.tax_rate.should == 0.5
    end
  end
  
  describe "得到指定玩家首都" do
    it "应该返回首都" do
      beijing  = FactoryGirl.create(:beijing)
      shanghai = FactoryGirl.create(:shanghai)
      City.capital_of(1).should == beijing
    end
  end

  describe "更新城市资源信息" do
    before do
      @beijing = FactoryGirl.create(:beijing)
    end

    it "应该 用当前城市信息" do
      @beijing.should_receive(:update_attributes).with(@beijing.current_resource_info)
      @beijing.update_resource
    end

    it "应该 touch最后更新资源的时间戳" do
      @beijing.should_receive(:touch).with(:last_updated_resource_at)
      @beijing.update_resource
    end


  end

  describe "改变税率" do
    before do 
      @beijing  = FactoryGirl.create(:beijing)
      @shanghai = FactoryGirl.create(:shanghai)
      City.stub(:capital_of).and_return(@beijing)
      City.stub(:find_by_player_id_and_id).and_return(@shanghai)
    end

    it "应该 找到玩家的首都" do
      City.should_receive(:capital_of).with(1)
      City.move_the_capital_to(1,@shanghai.id)
    end

    it "应该 找到玩家将要成为首都的城市(准首都)" do
      City.should_receive(:find_by_player_id_and_id).with(1,@shanghai.id)
      City.move_the_capital_to(1,@shanghai.id)
    end

    it "应该 更新首都的资源" do
      @beijing.should_receive(:update_resource)
      City.move_the_capital_to(1,@shanghai.id)
    end

    it "应该 更新准首都的资源" do
      @shanghai.should_receive(:update_resource)
      City.move_the_capital_to(1,@shanghai.id)
    end

    it "应该 更改首都属性" do
      City.move_the_capital_to(1,@shanghai.id)
      @shanghai.capital.should == true
      @beijing.capital.should  == false
    end
  end

  describe "查询城市各兵种数量" do
    it "长枪兵数量" do
      @pikemen = FactoryGirl.create(:pikemen,:number => 1)
      @pikemen.city.pikemen_number.should == 1
    end

    it "弓箭手数量" do
      @archer  = FactoryGirl.create(:archer,:number => 2)
      @archer.city.archer_number.should == 2
    end

    it "骑士数量" do 
      @cavalry = FactoryGirl.create(:cavalry,:number => 3)
      @cavalry.city.cavalry_number.should == 3
    end

    it "当不存 一个兵种的部队时返回nil" do
      @troop = FactoryGirl.create(:cavalry,:number => 3)
      @troop.city.pikemen_number.should == nil
    end

    it "某部队人数为0时，返回0" do
      @cavalry = FactoryGirl.create(:cavalry,:number => 0)
      @cavalry.city.cavalry_number.should == 0
    end
  end
end


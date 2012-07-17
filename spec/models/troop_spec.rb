# -*- coding: utf-8 -*-
require 'spec_helper'

describe Troop do
  describe "数据校验" do
    before do
      @pikemen = FactoryGirl.create(:pikemen,:city_id => 2)
    end

    it "每个兵种 在一个城市只能有一只部队" do
      @pikemen2 = FactoryGirl.build(:pikemen,:city_id => 2)
      @pikemen2.should_not be_valid
    end
  end

  describe "创建士兵" do
    before do
      @shanghai = FactoryGirl.create(:shanghai)
    end 
   
    context "如果 城市尚且没有此兵种的部队" do
      it "应该 创建此兵种部队" do
        Troop.should_receive(:create).with(:city_id => @shanghai.id,:soldier_type => 3 , :number =>1 )
        Troop.build :city_id => @shanghai.id,:soldier_type => 3  
      end
      
      it "部队人数为1" do
        Troop.build :city_id => @shanghai.id,:soldier_type => 3
        City.find(@shanghai.id).cavalry_number.should == 1
      end
    end

    context "如果 城市中已经有了此兵种的部队" do
      before do
        @archer = FactoryGirl.create(:archer,:city_id => @shanghai.id,:number => 20 )
      end

      it "部队人数加一" do
        Troop.build :city_id => @shanghai.id,:soldier_type => 2
        @archer.reload.number.should == 21
      end
    end

    it "应该 更新城市的资源" do
      Troop.build :city_id => @shanghai.id,:soldier_type => 2      
      (@shanghai.reload.last_updated_resource_at - DateTime.now).to_i.should == 0
    end
  end
end

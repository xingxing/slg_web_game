# -*- coding: utf-8 -*-
require 'spec_helper'

describe Event do
  describe "计划征税" do
    before do
      DateTime.stub!(:now).and_return(DateTime.parse("1970-01-01 00:00:00"))
      @tax = Event.plans_to_tax 1
    end

    it "应该　创建类型为征税的事件" do
      @tax.event_type.should == Event::Type[:tax]
    end

    it "应该　将结束时间设为一小时以后" do
      @tax.ends_at.should == DateTime.parse("1970-01-01 01:00:00")
    end
  end

  describe "征税" do
    before do
      @tax = FactoryGirl.create(:tax)
    end
    
    it "征税金额 = 人口*税率" do
      @tax.ends
      @tax.city.glod = (@tax.city.population * @tax.city.tax_rate).round
    end

    context "如果 人口数量 < 税率*1000" do
      it "人口数量提升5%"
      it "人口最少增加单位为1"
      it "人口最大增加单位为1000"
    end
    
    context "如果 人口数量 > 税率*1000" do
      it "人口数量减少5%"
      it "人口最少减少单位为1"
      it "人口最大增加单位为1000"
    end
  end
end

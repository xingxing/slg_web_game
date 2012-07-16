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

  describe "完成事件" do
    before do
      @tax = FactoryGirl.create(:tax)
    end

    it "应该 调用事件处理方法" do
      @tax.should_receive(:tax)
      @tax.ends
    end

    it "应该 删除事件记录" do
      @tax.should_receive(:destroy)
      @tax.ends
    end
  end

  describe "征税" do
    before do
      @tax = FactoryGirl.create(:tax)
    end

    it "应该 更新城市资源" do
      @tax.city.should_receive(:update_resource)
      @tax.ends
    end


    it "征税金额 = 人口*税率" do
      population = @tax.city.population  
      tax_rate    = @tax.city.tax_rate
      @tax.ends
      @tax.city.glod.should == (population*tax_rate).round
    end

    it "应该 计划下次收税的时间" do
      Event.should_receive(:plans_to_tax).with(@tax.city.id)
      @tax.ends
    end
    
    it "粮食增长相应数量" do
      @tax.city.stub(:last_updated_resource_at).and_return(1.hour.ago)
      @tax.ends
      @tax.city.food.should == City::AgriculturalOutputPerHourOfTheCapital
    end

    context "如果 人口数量 < 税率*1000" do
      before do
        @shanghai = FactoryGirl.create(:shanghai,:tax_rate => 0.3,:population => 299)
        @tax.stub!(:city).and_return(@shanghai)
      end

      it "人口数量提升5%" do
        @tax.ends
        @shanghai.population.should == (299*(1+0.05)).to_i
      end

      it "人口最少增加单位为1" do
        shanghai = FactoryGirl.create(:shanghai,:tax_rate => 0.3,:population => 19)
        @tax.stub!(:city).and_return(shanghai)
        @tax.ends
        shanghai.population.should == 19+1
      end

      it "人口最大增加单位为1000" do
        shanghai = FactoryGirl.create(:shanghai,:tax_rate => 30,:population => 21000 )
        @tax.stub!(:city).and_return(shanghai)
        @tax.ends
        shanghai.population.should == 21000 + 1000
      end
    end
    
    context "如果 人口数量 > 税率*1000" do
      before do
        @shanghai = FactoryGirl.create(:shanghai,:tax_rate => 0.3,:population => 400)
        @tax.stub!(:city).and_return(@shanghai)
      end

      it "人口数量减少5%" do
        @tax.ends 
        @shanghai.population.should == 400 - (400*0.05).to_i 
      end
      
      it "人口最少减少单位为1" do
        shanghai = FactoryGirl.create(:shanghai,:tax_rate => 0.003,:population => 19)
        @tax.stub!(:city).and_return(shanghai)
        @tax.ends
        shanghai.population.should == 19-1  
      end

      it "人口最大增加单位为1000" do
        shanghai = FactoryGirl.create(:shanghai,:tax_rate => 0.3,:population => 21000)
        @tax.stub!(:city).and_return(shanghai)
        @tax.ends
        shanghai.population.should == 21000 - 1000
      end
    end
  end
end

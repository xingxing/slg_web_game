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

    context "如果 发生粮食危机(粮食为0)" do
      before do
        @taibei = FactoryGirl.create(:taibei,:food => 0)

        @cavalry = FactoryGirl.create(:cavalry,
                                      :number => 10,
                                      :city_id => @taibei.id)

        @pikemen = FactoryGirl.create(:pikemen,
                                      :number => 100,
                                      :city_id => @taibei.id)

        @archer  = FactoryGirl.create(:archer,
                                      :number => 12,
                                      :city_id => @taibei.id)
      end

      it "各个 部队的人数下降10%" do
        Event.plans_to_tax(@taibei.id).ends
        @pikemen.reload.number.should == 90
        @archer.reload.number.should ==  11
        @cavalry.reload.number.should == 9
      end
    end

    describe "征税后的人口变动" do
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

  describe "计划训练士兵" do
    context "如果 金钱足以支付训练费并且训练人数大于士兵人数" do
      before do
        @shanghai = FactoryGirl.create(:shanghai,:glod => 100,:population => 900)
      end

      context "如果 一座城市已经5批士兵等待接受训练" do
        before do
          training1 = Event.plans_to_train(@shanghai.id,:pikemen,10)
          training2 = Event.plans_to_train(@shanghai.id,:pikemen,10)
          training3 = Event.plans_to_train(@shanghai.id,:pikemen,10)
          training4 = Event.plans_to_train(@shanghai.id,:pikemen,10)
          training5 = Event.plans_to_train(@shanghai.id,:pikemen,10)
        end

        it "应该 返回nil" do
          Event.plans_to_train(@shanghai.id,:pikemen,10).should == nil 
        end

        it "新训练不会被保存" do
          Event.plans_to_train(@shanghai.id,:pikemen,10)
          Event.where(city_id: @shanghai.id,event_type: Event::Type[:train]).size.should == 5 
        end

        it "新训练的子事件不会被保存" do
          Event.plans_to_train(@shanghai.id,:pikemen,10)
          Event.where(city_id: @shanghai.id,event_type: Event::Type[:build]).size.should == 50
        end
        
        it "城市的人口和金子不会减少" do
          Event.plans_to_train(@shanghai.id,:pikemen,10)
          @shanghai.reload.glod.should == 100 - 10 * 5
          @shanghai.reload.population.should == 900 - 10 * 5
        end
      end

      it "应该 创建训练人数个士兵建造子事件" do
        build_soldier = FactoryGirl.create(:build_soldier) 
        Event.should_receive(:plans_to_build_soldier).exactly(10).times.and_return(build_soldier)
        @training = Event.plans_to_train(@shanghai.id,:pikemen,10)
      end

      it "应该 记录每个士兵建造子事件" do
        build_soldier = FactoryGirl.create(:build_soldier) 
        Event.stub(:plans_to_build_soldier).and_return(build_soldier)
        @training = Event.plans_to_train(@shanghai.id,:pikemen,10)
        @training.event_content[:sub_event_ids] = [build_soldier.id] * 10
      end

      it "应该 记录这批训练的兵种和人数" do
        @training = Event.plans_to_train(@shanghai.id,:pikemen,10)
        @training.event_content[:soldier_type].should == :pikemen
        @training.event_content[:number].should == 10
      end

      it "一批训练应该和最后一个造人子事件的完成时间相同" do
        @training = Event.plans_to_train(@shanghai.id,:cavalry,10)
        @training.ends_at.should == @training.sub_events.last.ends_at
      end

      it "子事件结束时间间隔兵种单位建造时间" do
        @training = Event.plans_to_train(@shanghai.id,:cavalry,3)
        sub_events = @training.sub_events
        (sub_events[2].ends_at - sub_events[1].ends_at).should == Troop::TrainTime[:cavalry] * 60
        (sub_events[2].ends_at - sub_events[1].ends_at).should == (sub_events[1].ends_at - sub_events[0].ends_at)
      end

      it "应该 花费该城市的训练金" do
        @training = Event.plans_to_train(@shanghai.id,:pikemen,10)
        @shanghai.reload.glod.should == 100 - 10
      end

      it "应该 将城市人口去掉训练的人数" do
        @training = Event.plans_to_train(@shanghai.id,:pikemen,10)
        @shanghai.reload.population.should == 900 - 10
      end
    end
    
    context "如果 金钱不足以支付训练费" do
      before do
        @shanghai = FactoryGirl.create(:shanghai,:glod => 9 )
        @training = Event.plans_to_train(@shanghai.id,:pikemen,10)
      end

      it "应该 返回nil" do
        @training.should == nil
      end
    end

    context "如果 训练人数大于士兵人数" do
      before do
        @shanghai = FactoryGirl.create(:shanghai,:population => 1 )
        @training = Event.plans_to_train(@shanghai.id,:pikemen,2)
      end

      it "应该 返回nil" do
        @training.should == nil
      end
    end
  end

  describe "建造单位" do
    it "调用相应类中build方法,以事件数据中的attr作为参数" do
      build_soldier = FactoryGirl.create(:build_soldier)
      Troop.should_receive(:build).with({city_id: 2,soldier_type: :cavalry} )
      build_soldier.build
    end
  end

  describe "取消一批训练" do
    before do
      @shanghai = FactoryGirl.create(:shanghai,:glod => 100,:population => 900)
      @training = Event.plans_to_train(@shanghai.id,:pikemen,10)
    end

    it "应该 删除尚未完成的子事件" do
      sub_event_ids = @training.event_content[:sub_event_ids]
      @training.cancel_train
      Event.where(id: sub_event_ids).size.should == 0
    end

    it "应该 更新城市的资源" do
      @training.city.should_receive(:update_resource)
      @training.cancel_train
    end

    it "应该 将未完成的士兵增加到城市人口" do
      @training.sub_events.first.destroy
      @training.cancel_train
      @shanghai.reload.population.should == 900-10+9
    end
  end

  describe "计划出兵" do
    before do
      @shanghai = FactoryGirl.create(:shanghai,:food => 100)
      @taibei   = FactoryGirl.create(:taibei)

      @pikemen = FactoryGirl.create(:pikemen,
                                    :city_id => @shanghai.id , 
                                    :number => 10) 

      @cavalry =  FactoryGirl.create(:cavalry,
                                     :city_id => @shanghai.id,
                                     :number => 4)

      @archer = FactoryGirl.create(:archer,
                                   :city_id => @shanghai.id,
                                   :number => 2)
      
    end

    it "需要 计算城市间的距离" do
      event = Event.plans_to_send_troops @shanghai.id,@taibei.id,{cavalry: 2,pikemen: 9}
      event.event_content[:distance].should == 213
    end

    it "需要 计算部队的整体移动速度并得到攻击时间(到达时间)" do
      event = Event.plans_to_send_troops @shanghai.id,@taibei.id,{cavalry: 2,pikemen: 9}
      event.ends_at.strftime("%Y%m%d%X").should == (213/1.5).round.minutes.since.strftime("%Y%m%d%X")
    end

    it "需要 减少城内戍卫的士兵人数" do
      Event.plans_to_send_troops @shanghai.id,@taibei.id,{cavalry: 2,pikemen: 9}
      @pikemen.reload.number.should == 10 - 9
      @cavalry.reload.number.should == 2
      @archer.reload.number.should == 2
    end
  end

  describe "攻击(出兵.ends)" do
    before do
      @shanghai = FactoryGirl.create(:shanghai,:food => 100)
      @taibei   = FactoryGirl.create(:taibei)

      @pikemen = FactoryGirl.create(:pikemen,
                                    :city_id => @shanghai.id , 
                                    :number => 10) 

      @cavalry =  FactoryGirl.create(:cavalry,
                                     :city_id => @shanghai.id,
                                     :number => 4)

      @archer = FactoryGirl.create(:archer,
                                   :city_id => @taibei.id,
                                   :number => 9)
      @plan = Event.plans_to_send_troops @shanghai.id,@taibei.id,{cavalry: 2,pikemen: 9}
    end

    it "需要 计划回城时间"

    it "需要 计算双方阵亡人数" do
      Kernel.stub!(:rand).and_return(2)
      p @plan.target_city 
      p @taibei
      @plan.ends
      @taibei.reload.archer_number.should == 7
    end

    it "需要 更新目标城市(守方)的资源" do
      @plan.target_city.should_receive(:update_resource)
      @plan.ends
    end

    it "需要 更新己方城市的资源" do
      @plan.city.should_receive(:update_resource)
      @plan.ends
    end
  end

  describe "计划回城" do
    it "需要 计算回城时间"
  end

  describe "回城.ends" do
    it "增加返回士兵人数到城市部队"
  end
end

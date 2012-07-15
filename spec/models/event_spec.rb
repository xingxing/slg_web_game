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
end

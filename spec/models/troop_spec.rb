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
end

# -*- coding: utf-8 -*-
FactoryGirl.define do
  factory :beijing, :class => City do
    player_id 1
    upper_left_x   0
    upper_left_y 0
    name  "北京"
    capital true
    tax_rate 0.2
    population 100
    glod     0
    food     0
  end

  factory :shanghai, :class => City do 
    player_id 1
    upper_left_x 30
    upper_left_y 100
    name  "上海"
    capital false
    tax_rate 0.2
    population 100
    glod     0
    food     0
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :troop do
    association :city, :factory => :shanghai

    factory :pikemen, :parent => :troop do 
      soldier_type Troop::SoldierTypes[:pikemen]
      number  10
    end

    factory :archer, :parent => :troop do 
      soldier_type Troop::SoldierTypes[:archer]
      number  10
    end

    factory :cavalry, :parent => :troop do 
      soldier_type Troop::SoldierTypes[:cavalry]
      number  10
    end
  end
end

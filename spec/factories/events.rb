# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tax,:class => Event do
    association :city, :factory => :beijing
    event_type Event::Type[:tax]
    ends_at    Time.now
  end

  factory :build_soldier,:class => Event do
    association :city , :factory => :shanghai
    event_type Event::Type[:build]
    ends_at  Time.now
    content  { Oj.dump({ klass: 'Troop' , attrs: {city_id: 2 ,soldier_type: :cavalry}}) }
  end

  factory :send_troops,:class => Event do
    association :city, :factory => :shanghai
    association :target_city, :factory => :taibei
    event_type Event::Type[:send_troops]
    ends_at  Time.now
    content  { Oj.dump({array: {pikemen: 4},:distance => 200  }) }
  end

  factory :troops_back,:class => Event do
    association :city, :factory => :taibei
    association :target_city, :factory => :shanghai
    event_type Event::Type[:troops_back]
    ends_at  Time.now
    content  { Oj.dump({array: {cavalry: 1000,pikemen: 400}}) }
  end
end

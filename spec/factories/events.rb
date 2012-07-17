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
  end
end

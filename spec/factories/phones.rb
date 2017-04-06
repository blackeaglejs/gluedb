FactoryGirl.define do
  factory :phone do
    phone_type 'home'
    sequence(:phone_number, 1111111111) { |n| "#{n}"}
    sequence(:extension) { |n| "#{n}"}
    primary true
  end

  trait :bad_phone_number do 
    phone_number '0'
  end
end
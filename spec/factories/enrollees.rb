FactoryGirl.define do
  factory :enrollee do
    sequence(:m_id) { |n| "#{n}"}
    ben_stat 'active'
    emp_stat 'active'
    rel_code 'self'
    ds false
    pre_amt '666.66'
    sequence(:c_id) { |n| "#{n}" }
    sequence(:cp_id) { |n| "#{n}" }
    coverage_start Date.new(2014,1,2)
    coverage_end Date.new(2014,3,4)
    coverage_status 'active'

    trait :self_relationship do
      rel_code 'self'
    end

    trait :spouse do
      rel_code 'spouse'
    end

    trait :child do
      rel_code 'child'
    end

    trait :ward do
      rel_code 'ward'
    end

    factory :subscriber_enrollee, traits: [:self_relationship]
    factory :spouse_enrollee, traits: [:spouse]
  end
end
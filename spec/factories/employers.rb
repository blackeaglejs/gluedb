FactoryGirl.define do
  factory :employer do
    name 'Das Coffee'
    sequence(:hbx_id) { |n| "#{n}"}
    sequence(:fein, 111111111) {|n| "#{n}" }
    sic_code '0100'
    fte_count 1
    pte_count 1
    open_enrollment_start Date.new(2014,1,2)
    open_enrollment_end Date.new(2014,1,2)
    plan_year_start Date.new(2014,1,2)
    plan_year_end Date.new(2014,1,2)

    after(:create) do |e, evaluator|
        create_list(:plan_year, 1, employer: e)
        create_list(:renewal_plan_year, 1, employer: e)
    end

    trait :fein_too_short do
      fein '1'
    end

    factory :invalid_employer, traits: [:fein_too_short]
  end
end

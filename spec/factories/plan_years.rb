FactoryGirl.define do 
	factory :plan_year do
		start_date Date.new(2016,1,1)
		end_date Date.new(2016,12,31)
		fte_count 1
    	pte_count 1
    	employer

    	trait :overlapping_dates do
    		start_date Date.new(2016,2,1)
    		end_date Date.new(2017,1,31)
    	end

    	trait :renewal_plan_year_dates do
    		start_date Date.new(2017,1,1)
    		end_date Date.new(2017,12,31)
    	end

    	factory :overlapping_plan_year, traits: [:overlapping_dates]
    	factory :renewal_plan_year, traits: [:renewal_plan_year_dates]
	end
end
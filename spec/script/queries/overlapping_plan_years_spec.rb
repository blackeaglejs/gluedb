require 'rails_helper'
require File.join(Rails.root, "script", "queries", "overlapping_plan_years")

describe 'plan_year_overlap?' do 
	it 'should return true if there are overlapping plan years' do
		employer = FactoryGirl.create :employer
		bad_plan_year = FactoryGirl.create :overlapping_plan_year
		bad_plan_year.employer = employer
		bad_plan_year.save
		expect(plan_year_overlap?(employer)).to eq true
	end

	it 'should return false if there are not overlapping plan years' do
		employer = FactoryGirl.create :employer
		expect(plan_year_overlap?(employer)).to eq false
	end
end
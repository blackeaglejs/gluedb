# Finds employers with overlapping plan years.

def plan_year_overlap?(employer)
	results = []
	plan_years = employer.plan_years
	employer.plan_years.each do |plan_year|
		plan_years.each do |py|
			next if py == plan_year
			result = plan_year.overlaps?(py)
			results.push(result)
		end
	end
	if results.any?{|result| result == true}
		return true
	else
		return false
	end
end

def plan_year_ranges(employer)
	ranges = []
	employer.plan_years.each do |plan_year|
		py_start = plan_year.start_date
		py_end = plan_year.end_date
		range = (py_start..py_end).to_s
		ranges.push(range)
	end
	return ranges.join(",")
end

CSV.open("overlapping_plan_years.csv","w") do |csv|
	csv << ["Employer Name", "Employer DBA", "Employer FEIN","Employer HBX ID","Plan Year Ranges"]
	Employer.all.each do |employer|
		overlap_check = plan_year_overlap?(employer)
		next if overlap_check == false
		name = employer.name
		dba = employer.dba
		fein = employer.fein
		hbx_id = employer.hbx_id
		plan_year_dates = plan_year_ranges(employer)
		csv << [name,dba,fein,hbx_id,plan_year_dates]
	end
end



class EligibilityDetermination::Medicaid

  attr_reader :newly_eligible_households

  CALANDER_YEAR = 2015

  ANNUAL_FPL_LEVELS = {
    1 => 11770,
    2 => 15930,
    3 => 20090,
    4 => 24250,
    5 => 28410,
    6 => 32570,
    7 => 36730,
    8 => 40890
  }

  MEDICAID_FPL_LEVELS = {
    'children_below_19' => 324,
    'pregnant_woman' => 324,
    'children_between_19_and_20' => 221,
    'parents_and_caretakers' => 221,
    'adults_without_children' => 215
  }

  def initialize(family = nil)
    @family = family
    @newly_eligible_households = []
  end

  def run_eligibility
    @family.active_household.tax_households_with_policies(CALANDER_YEAR).each do |tax_household, policies|

      @irs_tax_household = Generators::Reports::IrsTaxHousehold.new(tax_household, policies)
      household_income = calculate_household_income(tax_household)
      fpl_percentage = calculate_fpl_percentage(tax_household, household_income)

      if is_household_eligible_for_medicaid?(tax_household, fpl_percentage)
        @newly_eligible_households << tax_household
      end
    end
  end

  def calculate_household_income(household)

  end

  def calculate_fpl_percentage(household, household_income)
    base_amount = 7610
    multiplier  = 4160
    (household_income.to_f / (base_amount + household.tax_household_members.size * multiplier)) * 100
  end

  def is_household_eligible_for_medicaid?(household, fpl_percentage)    
    household.tax_household_members.none? do |tax_household_member| 
      !fpl_medicaid_eligble?(tax_household_member, fpl_percentage)
    end
  end

  def fpl_medicaid_eligble?(tax_household_member, fpl_percentage)
    medicaid_category = medicaid_fpl_category(tax_household_member)
    MEDICAID_FPL_LEVELS[medicaid_category] > fpl_percentage ? true : false
  end

  def medicaid_fpl_category(tax_household_member)
    category = 'adults_without_children'
    if @irs_tax_household.primary == tax_household_member || @irs_tax_household.spouse == tax_household_member
      category = 'parents_and_caretakers' if @irs_tax_household.dependents.any? 
    elsif @irs_tax_household.dependents.include?(tax_household_member)
      if age(tax_household_member) < 19 
        category = 'children_below_19'
      elsif age(tax_household_member) < 21
        category = 'children_between_19_and_20'
      end
    end
    return category
  end

  def age(tax_household_member)
    family_member = tax_household_member.family_member
    if family_member.person.blank? || family_member.person.authority_member.blank?
      raise "person record seems to be wrong #{@family.e_case_id}"
    end
    ager = Ager.new(family_member.person.authority_member.dob)
    ager.age_as_of(Date.today)
  end
end
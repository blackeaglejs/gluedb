module Parsers::Xml::Cv
  class Income
    include NodeUtils

    TYPE_MAP = {
      'alimony and maintenance' => 'alimony_and_maintenance',
      'capital gains' => 'capital_gains',
      'dividends' => 'dividend',
      'estate and trust income' => 'estate_trust',
      'farming or fishing income' => 'farming_and_fishing',
      'foreign income' => 'foreign',
      'interest' => 'interest',
      'lump sum amount' => 'lump_sum_amount',
      'military pay' => 'military',
      'net self employment income' => 'net_self_employment',
      'other' => 'other',
      'pension/retirement benefits' => 'pension_retirement_benefits',
      'pensions/retirement benefits' => 'pension_retirement_benefits',
      "permanent worker's compensation" => 'permanent_workers_compensation',
      'prizes and awards' => 'prizes_and_awards',
      'rental or royalty income' => 'rental_and_royalty',
      'scholarship payments' => 'scholorship_payments',
      'social security benefit' => 'social_security_benefit',
      'supplemental security income' => 'supplemental_security_income',
      'tax-exempt interest' => 'tax_exempt_interest',
      'unemployment insurance' => 'unemployment_insurance',
      'wages and salaries' => 'wages_and_salaries'
    }

    FREQUENCY_MAP = {
      'bi-weekly' => 'biweekly',
      'half yearly' => 'half_yearly',
      'monthly' => 'monthly',
      'quarterly' => 'quarterly',
      'weekly' => 'weekly',
      'yearly' => 'yearly'
    }

    def initialize(parser)
      @parser = parser
    end

    def dollar_amount
      @parser.at_xpath('./ns1:amount', NAMESPACES).text.to_f.round(2)
    end

    def type
      data = first_text('./ns1:type')
      data.blank? ? nil : TYPE_MAP[data.downcase]
    end

    def frequency
      data = first_text('./ns1:frequency')
      data.blank? ? nil : FREQUENCY_MAP[data.downcase]
    end

    def start_date
      first_date('./ns1:start_date')
    end

    def end_date
      first_date('./ns1:end_date')
    end

    def submitted_date
      first_date('./ns1:submitted_date')
    end

    def amount_in_cents
      (dollar_amount * 100).to_i
    end

    def empty?
      [dollar_amount,type,frequency].any?(&:blank?)
    end

    def to_request
      {
        :submitted_date => submitted_date,
        :start_date => start_date,
        :end_date => end_date,
        :kind => type,
        :frequency => frequency,
        :amount_in_cents => amount_in_cents
      }
    end
  end
end

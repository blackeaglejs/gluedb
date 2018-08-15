require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrolleeEndDate < MongoidMigrationTask
  
  def input_valid?
    true if ENV['eg_id'].present? && ENV['m_id'].present? && ENV['start_date'].present? && ENV['new_end_date'].present?
  end
  
  def migrate
    if input_valid?
      policy = Policy.where(eg_id: ENV['eg_id']).first
      m_id = ENV['m_id']
      start_on = Date.strptime(ENV['start_date'].to_s, '%m/%d/%Y')
      end_on = Date.strptime(ENV['new_end_date'].to_s, "%m/%d/%Y")
      if policy.blank?
        puts "No hbx_enrollment was found with the given hbx_id" unless Rails.env.test?
      else
        enrollee=policy.enrollees.where(m_id: m_id, coverage_start: start_on).first
        enrollee.update_attributes!(coverage_end: end_on)
          puts "enrollee coverage end modified...!" unless Rails.env.test?
      end
    else 
      puts "You are missing an Environment variable, please check your input" unless Rails.env.test?
    end
  end
end
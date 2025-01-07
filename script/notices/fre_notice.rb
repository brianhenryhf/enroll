# frozen_string_literal: true

require File.join(Rails.root, "app", "notices", "ivl_notices", "fre_notice")

# This script is used to trigger FRE notice processes.
# There are three modes available:
#  1. trigger_notices: This mode triggers generation of the FRE notices for all eligible consumers.
#  2. notices_report: This mode generates a FRE report indicating if an eligible consumer has or has not received the notice based on the provided date params.
#  3. failed_validation_report: This mode generates a FRE report indicating if there is an issue with either CV3 transform or CV3 contract validation for each family record that should have an FRE notice generated but did not yet receive one.

# The first argument passed to the script is the mode. Must be one of: trigger_notices, notices_report, failed_validation_report.
# The second argument passed to the script is the effective_on date of the renewal enrollments, i.e., the first day of the upcoming year.
# The third argument passed to the script is the created_on date to check for existing FRE notices. The operation will only take action for consumers who do not have a FRE notice created on or after the created_on date.

# Example usage:
#
# To generate the FRE notices use:
#   bundle exec rails runner script/notices/fre_notice.rb 'trigger_notices' '2025-01-01' '2025-11-1'
#
# To generate the FRE report after notices have been generated use:
#   bundle exec rails runner script/notices/fre_notice.rb 'notices_report' '2025-01-01' '2025-11-1'
#
# To generate the FRE failed validations report after notices have been generated use:
#   bundle exec rails runner script/notices/fre_notice.rb 'failed_validation_report' '2025-01-01' '2025-11-1'


unless ARGV[0].present? && ARGV[1].present? && ARGV[2].present?
  puts "Missing arguments. Please provide the mode and effective_on and created_on dates. Example: bundle exec rails runner script/notices/fre_notice.rb 'trigger_notices' '2025-01-01' '2025-11-1'"
  exit
end

mode = ARGV[0]

effective_on = begin
  ARGV[1].to_date
rescue StandardError => e
  puts "Error: #{e.message}. effective_on date must be in the format 'YYYY-MM-DD'"
  exit
end

created_on = begin
  ARGV[2].to_date
rescue StandardError => e
  puts "Error: #{e.message}. created_on date must be in the format 'YYYY-MM-DD'"
  exit
end

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
result = ::Notices::IvlNotices::FreNotice.new.call({ mode: mode, effective_on: effective_on, created_on: created_on })
end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
seconds_elapsed = end_time - start_time
formatted_time = format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)

if result.success?
  p result.success
else
  p result.failure
end

p "********** FINISHED in #{formatted_time}"
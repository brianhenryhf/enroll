# frozen_string_literal: true

Given(/^the user answers no to having an income from an employer$/) do
  sleep 1
  find(IvlIapJobIncomeInformationPage.has_job_income_no_radiobtn).click
end

Then(/^the job income form should not show$/) do
  expect(page).not_to have_xpath("//*[@id='income_employer_name']")
  expect(page).not_to have_xpath("//*[@id='income_employer_address_address_1']")
end

Given(/^the user answers no to having self employment income$/) do
  find(IvlIapJobIncomeInformationPage.has_self_employee_income_no_radiobtn).click
  sleep 1
end

Then(/^self employment form should not show$/) do
  expect(page).not_to have_xpath("//*[@id='income_amount']")
end

Given(/^the user answers yes to having and income from an employer$/) do
  find(IvlIapJobIncomeInformationPage.has_job_income_yes_radiobtn).click
  sleep 1
end

Then(/^the job income form should show$/) do
  expect(page).to have_xpath("//*[@id='income_employer_name']")
  expect(page).to have_xpath("//*[@id='income_employer_phone_full_phone_number']")
end

Given(/^the user answers yes to having self employment income$/) do
  find(IvlIapJobIncomeInformationPage.has_self_employee_income_yes_radiobtn).click
  sleep 1
end

Then(/^self employment form should show$/) do
  expect(page).to have_xpath("//*[@id='income_amount']")
end

And(/^the user fills out the required employer information$/) do
  fill_in IvlIapJobIncomeInformationPage.employer_name, with: "Sample Employer"
  fill_in IvlIapJobIncomeInformationPage.income_amount, with: '23.3'
  find_all(IvlIapJobIncomeInformationPage.frequency).first.click
  find(IvlIapJobIncomeInformationPage.select_yearly).click
  fill_in IvlIapJobIncomeInformationPage.income_from, with: "11/11/2016"
  fill_in IvlIapJobIncomeInformationPage.income_to, with: "11/11/2017"
  find(IvlIapJobIncomeInformationPage.calendar).click
  fill_in IvlIapJobIncomeInformationPage.income_employer_phone_number, with: "2036548484"
  unless FinancialAssistanceRegistry[:disable_employer_address_fields].enabled?
    fill_in IvlIapJobIncomeInformationPage.income_employer_address_1, with: "12 main st"
    fill_in IvlIapJobIncomeInformationPage.income_employer_address_2, with: "beside starbucks"
    fill_in IvlIapJobIncomeInformationPage.income_employer_city, with: "washington"
    find(IvlIapJobIncomeInformationPage.income_employer_state_dropdown).click
    find(IvlIapJobIncomeInformationPage.select_va_state).click
    fill_in IvlIapJobIncomeInformationPage.income_employer_zip, with: "22046"
  end
end

And(/^the user fills out the required employer information with incorrect dates$/) do
  fill_in IvlIapJobIncomeInformationPage.employer_name, with: "Sample Employer"
  fill_in IvlIapJobIncomeInformationPage.income_amount, with: '23.3'
  find_all(IvlIapJobIncomeInformationPage.frequency).first.click
  find(IvlIapJobIncomeInformationPage.select_yearly).click
  fill_in IvlIapJobIncomeInformationPage.income_from, with: "11/11/2017"
  fill_in IvlIapJobIncomeInformationPage.income_to, with: "11/11/2016"
  find(IvlIapJobIncomeInformationPage.calendar).click
  fill_in IvlIapJobIncomeInformationPage.income_employer_phone_number, with: "2036548484"
  unless FinancialAssistanceRegistry[:disable_employer_address_fields].enabled?
    fill_in IvlIapJobIncomeInformationPage.income_employer_address_1, with: "12 main st"
    fill_in IvlIapJobIncomeInformationPage.income_employer_address_2, with: "beside starbucks"
    fill_in IvlIapJobIncomeInformationPage.income_employer_city, with: "washington"
    find(IvlIapJobIncomeInformationPage.income_employer_state_dropdown).click
    find(IvlIapJobIncomeInformationPage.select_va_state).click
    fill_in IvlIapJobIncomeInformationPage.income_employer_zip, with: "22046"
  end
end

And(/^the user enters a start date in the future$/) do
  fill_in IvlIapJobIncomeInformationPage.income_from, with: Date.new(Date.today.year + 1, 1, 1).strftime('%m/%d/%Y')
  find(IvlIapJobIncomeInformationPage.calendar).click
end

Then(/^the user should see the start date warning message$/) do
  find("#date_warnings_list", wait: 5)
  expect(page).to have_selector(IvlIapJobIncomeInformationPage.start_date_warning)
  expect(page).not_to have_selector(IvlIapJobIncomeInformationPage.end_date_warning)
end

And(/^the user enters an end date$/) do
  fill_in IvlIapJobIncomeInformationPage.income_to, with: Date.today.strftime('%m/%d/%Y')
  find(IvlIapJobIncomeInformationPage.calendar).click unless EnrollRegistry.feature_enabled?(:bs4_consumer_flow)
end

And(/^the user enters a too long end date$/) do
  fill_in IvlIapJobIncomeInformationPage.income_to, with: "12/01/202424"
  find(IvlIapJobIncomeInformationPage.calendar).click unless EnrollRegistry.feature_enabled?(:bs4_consumer_flow)
end

Then(/^the user should see a cut off date$/) do
  expect(find_field(IvlIapJobIncomeInformationPage.income_to).value.length).to eq 10
end

Then(/^the user should see the end date warning message$/) do
  find("#date_warnings_list", wait: 5)
  expect(page).not_to have_selector(IvlIapJobIncomeInformationPage.start_date_warning)
  expect(page).to have_selector(IvlIapJobIncomeInformationPage.end_date_warning)
end

Then(/^the user should see the end date warning modal$/) do
  find('#end_date_warning_modal')
  expect(page.has_css?("#end_date_warning_modal")).to eq true
end

Then(/^the user should see the start date and end date warning messages$/) do
  find("#date_warnings_list", wait: 5)
  expect(page).to have_selector(IvlIapJobIncomeInformationPage.start_date_warning)
  expect(page).to have_selector(IvlIapJobIncomeInformationPage.end_date_warning)
end

And(/^the user saves the employer information$/) do
  find(IvlIapJobIncomeInformationPage.income_save_btn).click
end

Then(/^the employer information should be saved on the page$/) do
  expect(page).to have_content("Sample Employer")
  expect(page).to have_content("23.3")
end

Given(/^the user has entered at least one job income information$/) do
  find(IvlIapJobIncomeInformationPage.has_job_income_yes_radiobtn).click
  sleep 1
  fill_in IvlIapJobIncomeInformationPage.employer_name, with: "Sample Employer1"
  fill_in IvlIapJobIncomeInformationPage.income_amount, with: '33.3'
  find_all(IvlIapJobIncomeInformationPage.frequency).first.click
  find(IvlIapJobIncomeInformationPage.select_yearly).click
  fill_in IvlIapJobIncomeInformationPage.income_from, with: "11/11/2016"
  fill_in IvlIapJobIncomeInformationPage.income_to, with: "11/11/2017"
  find(IvlIapJobIncomeInformationPage.calendar).click
  fill_in IvlIapJobIncomeInformationPage.income_employer_phone_number, with: "2036548484"
  unless FinancialAssistanceRegistry[:disable_employer_address_fields].enabled?
    fill_in IvlIapJobIncomeInformationPage.income_employer_address_1, with: "12 main st"
    fill_in IvlIapJobIncomeInformationPage.income_employer_address_2, with: "beside starbucks1"
    fill_in IvlIapJobIncomeInformationPage.income_employer_city, with: "washington"
    find(IvlIapJobIncomeInformationPage.income_employer_state_dropdown).click
    find(IvlIapJobIncomeInformationPage.select_va_state).click
    fill_in IvlIapJobIncomeInformationPage.income_employer_zip, with: "22046"
  end
  find(IvlIapJobIncomeInformationPage.income_save_btn).click
end

When(/^the Add Another Job Income link appears$/) do
  find('.interaction-click-control-add-another-job-income').visible?
end

When(/^the user adds another income$/) do
  find('#new-income').double_click
end

Then(/^the new employer information should be saved on the page$/) do
  expect(page).to have_content("Sample Employer")
  expect(page).to have_content("23.3")
  expect(page).to have_content("Sample Employer1")
  expect(page).to have_content("33.3")
  unless FinancialAssistanceRegistry[:disable_employer_address_fields].enabled?
    expect(page).to have_content("beside starbucks")
    expect(page).to have_content("beside starbucks1")
  end
end

And(/^the user fills out the required self employment information$/) do
  fill_in IvlIapJobIncomeInformationPage.income_amount, with: '23.3'
  find(IvlIapJobIncomeInformationPage.self_employee_frequency).click
  find(IvlIapJobIncomeInformationPage.self_employed_yearly).click
  fill_in IvlIapJobIncomeInformationPage.income_from, with: "11/11/2016"
  fill_in IvlIapJobIncomeInformationPage.income_to, with: "11/11/2017"
  find(IvlIapJobIncomeInformationPage.calendar).click
end

And(/^the user fills out the required self employment information with incorrect dates$/) do
  fill_in IvlIapJobIncomeInformationPage.income_amount, with: '23.3'
  find(IvlIapJobIncomeInformationPage.self_employee_frequency).click
  find(IvlIapJobIncomeInformationPage.self_employed_yearly).click
  fill_in IvlIapJobIncomeInformationPage.income_from, with: "11/11/2017"
  fill_in IvlIapJobIncomeInformationPage.income_to, with: "11/11/2016"
  find(IvlIapJobIncomeInformationPage.calendar).click
end

Given(/^the user has entered at least one self employment information$/) do
  find(IvlIapJobIncomeInformationPage.has_self_employee_income_yes_radiobtn).click
  sleep 1
  fill_in IvlIapJobIncomeInformationPage.income_amount, with: '23.3'
  find(IvlIapJobIncomeInformationPage.self_employee_frequency).click
  find(IvlIapJobIncomeInformationPage.self_employed_yearly).click
  fill_in IvlIapJobIncomeInformationPage.income_from, with: "11/11/2016"
  fill_in IvlIapJobIncomeInformationPage.income_to, with: "11/11/2017"
  find(IvlIapJobIncomeInformationPage.calendar).click
  find(IvlIapJobIncomeInformationPage.self_self_employee_save_btn).click
end

Then(/^the self employment information should be saved on the page$/) do
  expect(page).to have_content("23.3")
  sleep 2
end

When(/^the Add Another Self Employment link appears$/) do
  find('#new-self-income').visible?
end

And(/^the user adds another self employment income$/) do
  sleep 2
  find(IvlIapJobIncomeInformationPage.self_add_another_self_employment).click
end

When(/^the user saves the self employment information$/) do
  find(IvlIapJobIncomeInformationPage.self_self_employee_save_btn).click
end

Given(/^the user is on the Job Income page$/) do
  expect(page).to have_content("Job Income for")
end

When(/^the user clicks the Not sure link next to the (.*) income question$/) do |income_type|
  sleep 2
  links = page.all('a')
  case income_type
  when 'employer'
    popup_link = links.detect { |link| link[:href].include?("#has_job_income") unless link[:href].blank? }
  when 'self employment'
    popup_link = links.detect { |link| link[:href].include?("#has_self_employment_income") unless link[:href].blank? }
  when 'unemployment'
    popup_link = links.detect { |link| link[:href].include?("#has_unemployment_income") unless link[:href].blank? }
  end
  popup_link.click
  sleep 2
end

And(/^the user closes the open income question modal$/) do
  close_button = page.all('button').detect { |button| button[:class] == 'close interaction-click-control-×' }
  close_button.click
end

Then(/^the user should see the popup for the (.*) income question$/) do |income_type|
  sleep 5
  case income_type
  when 'job'
    # stuff
    popup_text = "Select ‘yes’ if this person is considered an employee of a business, or receives a W-2 federal form from any employer. " \
    "We need to know about all income this person receives from an employer, including wages, tips, salaries, and bonuses."
  when 'self employment'
    popup_text = "Select ‘yes’ if this person owns a business or receives a federal form 1099 from any employer. " \
    "We need to know about any income this person receives as an independent contractor or from a business they own."
  when 'unemployment'
    assistance_year = FinancialAssistance::Operations::EnrollmentDates::ApplicationYear.new.call.value!.to_s
    popup_text = "Select ‘yes’ if this person received one or more types of unemployment income listed below at any point in #{assistance_year}"
  end
  expect(page).to have_content(popup_text)
end

Then(/^the user will be on the Other Income page$/) do
  expect(page).to have_content("Other Income for")
end

And(/^there will be a checkmark next to the completed Job Income page link$/) do
  checkmark = page.all('span').detect { |span| span[:class] == "fa fa-check applicant-check" }
  expect(checkmark.present?).to eq(true)
end

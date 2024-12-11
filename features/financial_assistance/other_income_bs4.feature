Feature: Start a new Financial Assistance Application and fills out Other Income form with Bootstrap 4 layout enabled

  Background: User logs in and visits applicant's other income page
    Given bs4_consumer_flow feature is enabled
    Given divorce agreement year feature is enabled
    Given FAA other_income_end_date_warning feature is enabled
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the consumer is RIDP verified
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
    When the user will navigate to the FAA Household Info page
    Given ssi types feature is enabled
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant

  Scenario: User enters unemployment income information with an end date
    Given the user answers yes to having unemployment income
    Then the user should see the end date warning note above the form
    And the user enters an end date
    Then the user should see the end date warning modal

  Scenario: User enters other income information with an end date
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    Then the user should see the end date warning note above the form
    And the user enters an end date
    Then the user should see the end date warning modal

  Scenario: User enters other income alimony information with an end date
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    Then the user should see the end date warning note above the form
    Then the user should see the end date warning note without the word receive twice
    And the user enters an end date
    Then the user should see the end date warning modal

  Scenario: User enters other income information with an end date longer than 4 digits
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    And the user enters a too long end date
    Then the user should see a cut off date

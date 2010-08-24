Feature: champion uses dragonfly to process images
  In order to be a champion
  A user uses dragonfly

  Background:
    Given we are using the app for images
    Given a stored image "beach.png" with dimensions 200x100

  Scenario: Go to url for original
    When I go to the url for "beach.png", with format 'png'
    Then the response should be OK
    And the response should have mime-type 'image/png'
    And the image should have width '200'
    And the image should have height '100'
    And the image should have format 'png'

  Scenario: Go to url for changed format version
    When I go to the url for "beach.png", with format 'gif'
    Then the response should be OK
    And the response should have mime-type 'image/gif'
    And the image should have width '200'
    And the image should have height '100'
    And the image should have format 'gif'

  Scenario: Go to url for soft resized version
    When I go to the url for "beach.png", with format 'png' and resize geometry '100x150'
    Then the response should be OK
    And the response should have mime-type 'image/png'
    And the image should have width '100'
    And the image should have height '50'
    And the image should have format 'png'

  Scenario: Go to url for hard resized version
    When I go to the url for "beach.png", with format 'png' and resize geometry '100x150!'
    Then the response should be OK
    And the response should have mime-type 'image/png'
    And the image should have width '100'
    And the image should have height '150'
    And the image should have format 'png'

  Scenario: use a parameters shortcut
    When I go to the url for "beach.png", with shortcut '100x150!'
    Then the response should be OK
    And the response should have mime-type 'image/png'
    And the image should have width '100'
    And the image should have height '150'
    And the image should have format 'png'

Feature: champion uses imagetastic to process images
  In order to be a champion
  A user uses imagetastic

  Background:
    Given a stored image "beach.png" with dimensions 200x100

  Scenario: Go to url for original
    When I go to the url for image "beach.png", with format 'png'
    Then the response should be OK
    And the response should have mime-type 'image/png'
    And the image should have width '200'
    And the image should have height '200'
    And the image should have format 'png'

  Scenario: Go to url for changed format version
    When I go to the url for image "beach.png", with format 'gif'
    Then the response should be OK
    And the response should have mime-type 'image/gif'
    And the image should have width '200'
    And the image should have height '200'
    And the image should have format 'gif'

  Scenario: Go to url for soft resized version
    When I go to the url for image "beach.png", with resize geometry '100x150'
    Then the response should be OK
    And the response should have mime-type 'image/png'
    And the image should have width '100'
    And the image should have height '100'
    And the image should have format 'png'

  Scenario: Go to url for hard resized version
    When I go to the url for image "beach.png", with resize geometry '100x150!'
    Then the response should be OK
    And the response should have mime-type 'image/png'
    And the image should have width '100'
    And the image should have height '150'
    And the image should have format 'png'

Feature: champion adds cover images to his albums
  In order to be a champion
  A user adds an image to his album

  Scenario: Add and view image
    When I go to the new album page
    And I attach the file "../../../samples/beach.png" to "album[cover_image]"
    And I press "Create"
    Then I should see "successfully created"
    And I should see "Look at this cover image!"
    When I look at the generated image
    Then I should see a PNG image of size 200x100

  Scenario: validation fails
    When I go to the new album page
    And I attach the file "../../../samples/sample.docx" to "album[cover_image]"
    And I press "Create"
    Then I should see "Cover image format is incorrect. It needs to be one of 'jpg', 'png', 'gif', but was 'docx'"

  Scenario: other validation fails
    When I go to the new album page
    And I fill in "album[name]" with "too long"
    And I attach the file "../../../samples/beach.png" to "album[cover_image]"
    And I press "Create"
    Then I should see "Name is too long"
    When I fill in "album[name]" with "short"
    And I press "Create"
    Then I should see "successfully created"
    And I should see "short"
    And I should see "Look at this cover image!"
    When I look at the generated image
    Then I should see a PNG image of size 200x100

  Scenario: view remote image
    Given an album "good" with attached file "beach.png"
    When I go to the page for album "good"
    And I look at the original image
    Then I should see a PNG image of size 280x355
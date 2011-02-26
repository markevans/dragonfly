Feature: champion adds cover images to his albums
  In order to be a champion
  A user adds an image to his album

  Scenario: Add and view image
    When I go to the new album page
    And I attach the file "../../../samples/beach.png" to "album[cover_image]"
    And I press "Create"
    Then I should see "successfully created"
    And I should see "Look at this cover image!"
    When I look at the generated beach image
    And I should see a PNG image of size 200x100

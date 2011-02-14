Feature: champion adds text images to his app
  In order to be a champion
  A user adds text images to his app

  Scenario: View text image
    When I go to the image for text "Hello", size "300x150!"
    Then I should see a PNG image of size 300x150

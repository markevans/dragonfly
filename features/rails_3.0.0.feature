Feature: champion uses dragonfly in his Rails 3.0.0 application
  In order to be a champion
  A user uses dragonfly in his Rails 3.0.0 application

  Scenario: Set up dragonfly using initializer
    Given a Rails 3.0.0 application set up for using dragonfly
    Then the manage_album_images cucumber features in my Rails 3.0.0 app should pass
    And the text_images cucumber features in my Rails 3.0.0 app should pass

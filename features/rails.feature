Feature: champion uses dragonfly in his Rails application
  In order to be a champion
  A user uses dragonfly in his Rails application

  Scenario: Set up dragonfly using initializer
    Given a Rails application set up for using dragonfly
    Then the manage_album_images cucumber features in my Rails app should pass
    And the text_images cucumber features in my Rails app should pass

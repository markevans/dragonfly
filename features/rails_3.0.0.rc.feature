Feature: champion uses dragonfly in his Rails 3.0.0.rc application
  In order to be a champion
  A user uses dragonfly in his Rails 3.0.0.rc application

  Scenario: Set up dragonfly using initializer
    Given a Rails 3.0.0.rc application set up for using dragonfly
    Then the manage_album_images cucumber features in my Rails 3.0.0.rc app should pass

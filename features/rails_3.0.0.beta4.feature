Feature: champion uses dragonfly in his Rails 3.0.0.beta4 application
  In order to be a champion
  A user uses dragonfly in his Rails 3.0.0.beta4 application

  Scenario: Set up dragonfly using initializer
    Given a Rails 3.0.0.beta4 application set up for using dragonfly
    Then the cucumber features in my Rails 3.0.0.beta4 app should pass

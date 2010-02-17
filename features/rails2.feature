Feature: champion uses dragonfly in his Rails 2 application
  In order to be a champion
  A user uses dragonfly in his Rails 2 application

  Background:
    Given a Rails 2.3.5 application set up for using dragonfly

  Scenario: Set up dragonfly using the generator
    When I use the Rails 2.3.5 generator to set up dragonfly
    Then the cucumber features in my Rails 2.3.5 app should pass

  Scenario: Set up dragonfly using config.gem require
    When I use config.gem to require the Rails 2.3.5 initializer
    Then the cucumber features in my Rails 2.3.5 app should pass

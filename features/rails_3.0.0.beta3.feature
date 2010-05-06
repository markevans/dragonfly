Feature: champion uses dragonfly in his Rails 3.0.0.beta3 application
  In order to be a champion
  A user uses dragonfly in his Rails 3.0.0.beta3 application

  Background:
    Given PENDING: Neither cucumber generators nor Rails templates seem to be working properly yet for Rails 3
    Given a Rails 3.0.0.beta3 application set up for using dragonfly

  Scenario: Set up dragonfly using the generator
    When I use the Rails 3.0.0.beta3 generator to set up dragonfly
    Then the cucumber features in my Rails 3.0.0.beta3 app should pass

  Scenario: Set up dragonfly using bundler require
    When I use the provided 3.0.0.beta3 initializer
    Then the cucumber features in my Rails 3.0.0.beta3 app should pass

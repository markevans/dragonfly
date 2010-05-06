Feature: champion uses dragonfly in his Rails 3.0.0.beta3 application
  In order to be a champion
  A user uses dragonfly in his Rails 3.0.0.beta3 application

  Background:
    Given PENDING: Neither cucumber generators nor Rails templates seem to be working properly yet for Rails 3
    Given a Rails 3.0.0.beta3 application set up for using dragonfly

  Scenario: Set up dragonfly using initializer
    When I use the provided 3.0.0.beta3 initializer
    Then the cucumber features in my Rails 3.0.0.beta3 app should pass

Feature: champion uses dragonfly in his Rails 3.0.0.beta application
  In order to be a champion
  A user uses dragonfly in his Rails 3.0.0.beta application

  Background:
    Given a Rails 3.0.0.beta application set up for using dragonfly

  # Scenario: Set up dragonfly using the generator
  #   When I use the Rails 3.0.0.beta generator to set up dragonfly
  #   Then the cucumber features in my Rails 3.0.0.beta app should pass

  Scenario: Set up dragonfly using bundler require
    When I use the provided 3.0.0.beta initializer
    # Then the cucumber features in my Rails 3.0.0.beta app should pass

Getting Started
===============

See below for a general guide for setting up Dragonfly.
See {file:UsingWithRails UsingWithRails} for setting up with Ruby on Rails.

Running as a Standalone Rack Application
----------------------------------------

Basic usage of a dragonfly app involves storing data,
then serving that data, either in its original form, processed, encoded or both.

A basic rackup file

    require 'dragonfly'

    Dragonfly::App[:my_app_name].configure do |c|
      # ...
      c.some_attribute = 'blah'
      # ...
    end

    run Dragonfly:App[:my_app_name]


Caching
-------

Using with Rails
----------------
Feature: winner uses dragonfly to serve different kinds of files
  In order to be a winner
  As a potential loser
  I want to be a winner

  Background:
    Given we are using the app for files

  Scenario: Go to url for original, without extension
    Given a stored file "sample.docx"
    When I go to the url for "sample.docx"
    Then the response should be OK
    And the response should have mime-type 'application/zip'
    And the response should have the same content as the file "sample.docx"

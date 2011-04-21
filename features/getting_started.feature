Feature: Getting started
  
  As a new user I want to quickly get an idea of how breeze works.
  
  Scenario: Start a new project
    Given I have an empty working directory
    When I run `breeze init`
    Then a file named "Thorfile" should exist
  
  Scenario: Start a new server
    Given my Thorfile contains access credentials and configuration
    When I run `thor server:create`
    And I run `thor describe:servers`
    Then the output should look like:
    """
    === SERVER INSTANCES ===========================================================================
    Name  Instance ID  IP Address .* Image ID                          Type      Zone        State
                                     YOUR-PRIVATE-AMI-OR-A-PUBLIC-ONE  t1.micro  us-east-1a  running
    """
  
  Scenario: Terminate a server
    Given I have started a server
    Then I can terminate the server with `thor server:destroy [SERVER ID] --force`

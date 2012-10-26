Feature: Manage DNS zones and records

  DNS zones and records can be created and destroyed.
  Records can also be imported from a file.

  Scenario: Create a DNS zone
    When I run `thor dns:zone:create example.com`
    Then the output should look like:
    """
    Zone ID: .*
    Name servers: .*
    """

  Scenario: Create a DNS record
    Given I have created a DNS zone
    Then I can add a record with `thor dns:record:create [ZONE ID] www.example.com. A 127.0.0.1`

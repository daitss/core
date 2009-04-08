Feature: Ingest
  Under certian conditions ingest should reject a package or snafu a package
  
  Scenario: a bad ieid is supplied
    Given a non-existant ieid
     When I ingest it
     Then I should get an error

  Scenario: an invalid package
    Given a aip that will fail validation
     When I ingest it
     Then the package should be rejected

  Scenario: an ingest should pick up from where it left off
    Given a non ingested AIP
      And a set of events       # that take place during ingest
     When I ingest it
     Then the previous events should not be duplicated

  Scenario Outline: a error occurs
    Given an AIP
      And a error of <level> error when performing <service>
     When I ingest it
     Then the package should be <status>

  Examples: interesting cases
    | service       | level | status   |
    | validation    | any   | snafu    |
    | per-file      | 500   | snafu    |
    | per-file      | 400   | ingested |
    | serialization | any   | snafu    |
    | store         | any   | snafu    |
    

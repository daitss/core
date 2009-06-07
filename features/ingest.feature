Feature: Ingest
  Under certain conditions ingest should reject a package or snafu a package
  
  Scenario Outline: a bad package urls
    Given an <type> package url
     When I ingest it
     Then I should get an <type> error

  Examples: bad package urls
            | type         |
            | unknown      |
            | unresolvable |

  Scenario: an invalid package
    Given an aip that will fail validation
     When I ingest it
     Then the package should be rejected

  Scenario: an ingest should pick up from where it left off
    Given a partially ingested AIP
     When I ingest it
     Then the package should be ingested
      And there should be no duplicate events

  Scenario Outline: a error occurs
    Given a good AIP
      And a error of <level> error when performing <service>
     When I ingest it
     Then the package should be <status>

  Examples: interesting cases
    | level | service       | status   |
    | any   | validation    | snafu    |
    | 500   | per-file      | snafu    |
    | 400   | per-file      | ingested |
    | any   | serialization | snafu    |
    | any   | store         | snafu    |

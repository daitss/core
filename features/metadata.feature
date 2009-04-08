Feature: Package Level Metadata
  Ingest should extract from the SIP descriptor: issue, volume, title
  if they are present. Otherwise they should not exist in the AIP.

  Scenario Outline: Extract metadata if it exists
    Given A package with <field> <status>
    When it is ingested
    Then <field> should be <status> in AIP resource

  Examples: present metadata
    | field  | status  |
    | issue  | present |
    | volume | present |
    | title  | present |

  Examples: missing metadata
    | field  | status  |
    | issue  | missing |
    | volume | missing |
    | title  | missing |

# Make it the configuration
SERVICE_URLS = {
  "actionplan" => "http://localhost:7000/actionplan/instructions",
  "validation" => "http://localhost:7000/validation/results",
  "provenance" => "http://localhost:7000/provenance",
  "description" => "http://localhost:7000/description/describe",
  "storage" => "http://localhost:7000/silo",
  "database" => 'sqlite3::memory:'
}

SILO_SANDBOX='/tmp/silo_sandbox'

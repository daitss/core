desc "irb console with the ingest environment"
task :console do
  `irb -Ilib -Ispec -rspec_helper`
end

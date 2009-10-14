desc "irb console with the ingest environment"
task :console do
  exec "irb -I lib -I spec"
end

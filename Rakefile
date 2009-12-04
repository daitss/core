namespace :rng do
  desc "validate aip schematron"
  task :validate do
    exec "xmllint --relaxng schematron.rng aip.stron --noout"
  end

  desc "generate rng from rnc"
  task :generate do
    exec "java -jar trang/trang.jar -I rnc -O rng schematron.rnc schematron.rng"
  end
end

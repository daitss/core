RSpec::Matchers.define :exist_on_fs do
  match do |actual|
    File.exist? actual
  end
end

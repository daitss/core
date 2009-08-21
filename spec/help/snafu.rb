Spec::Matchers.define :be_snafu do

  match do |aip|
    aip.snafu?
  end

  failure_message_for_should do |aip|
    "expected #{aip} to be in SNAFU but was not"
  end
  
  failure_message_for_should_not do |aip|
    "expected #{aip} not to be in SNAFU but was\n" + open(aip.snafu_tag_file) { |io| io.read  }
  end
  
end

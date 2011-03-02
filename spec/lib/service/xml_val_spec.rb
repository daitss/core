describe XmlVal do
  let(:valid) { file_fixture_path 'valid.xml' }
  let(:warning) { file_fixture_path 'warning.xml' }
  let(:invalid) { file_fixture_path 'invalid.xml' }
  let(:illformed) { file_fixture_path 'illformed.xml' }

  it 'have not errors for a valid document' do
    warnings, errors, fatals = XmlVal.validate valid

    warnings.should be_empty
    errors.should be_empty
    fatals.should be_empty
  end

  it 'should report warnings' do
    warnings, errors, fatals = XmlVal.validate warning

    warnings.should_not be_empty
    warnings.should include(:public_id=>"",
                            :system_id=>"warning.xml",
                            :line=>14,
                            :column=>22,
                            :message=>"schema_reference.4: Failed to read schema document 'http://www.loc.xxx/standards/mods/v3/mods-3-3.xsd', because 1) could not find the document; 2) the document could not be read; 3) the root element of the document is not .\n        ")
    warnings.should include(:public_id=>"",
                            :system_id=>"warning.xml",
                            :line=>15,
                            :column=>21,
                            :message=>"schema_reference.4: Failed to read schema document 'http://www.loc.xxx/standards/mods/v3/mods-3-3.xsd', because 1) could not find the document; 2) the document could not be read; 3) the root element of the document is not .\n        ")
    warnings.should include(:public_id=>"",
                            :system_id=>"warning.xml",
                            :line=>8,
                            :column=>17,
                            :message=>"cvc-elt.1: Cannot find the declaration of element 'mets'.")

    errors.should_not be_empty
    fatals.should be_empty
  end

  it 'should have errors for a invalid document' do
    warnings, errors, fatals = XmlVal.validate invalid

    warnings.should be_empty
    errors.should_not be_empty
    errors.should include(:public_id => "",
                          :system_id => "invalid.xml",
                          :line => 42,
                          :column =>8,
                          :message=>"cvc-complex-type.2.4.b: The content of element 'mets' is not complete. One of '{\"http://www.loc.gov/METS/\":structMap}' is expected.")
    fatals.should be_empty
  end

  it 'should have fatals for an ill-formed document' do
    warnings, errors, fatals = XmlVal.validate illformed

    warnings.should be_empty
    errors.should be_empty
    fatals.should_not be_empty
    fatals.should include(:public_id=>"",
                          :system_id=>"illformed.xml",
                          :line=>11,
                          :column=>3,
                          :message=>"Element type \"this-is-bad\" must be followed by either attribute specifications, \">\" or \"/>\".")
  end

end

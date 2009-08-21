Spec::Matchers.define :exist_on_fs do

  match do |file|
    File.exist? file    
  end

end

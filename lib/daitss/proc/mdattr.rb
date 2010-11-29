require 'fileutils'

module MDAttr

  def md_attr sym

    # @return [String] the path of the file holding the metadata
    define_method :"#{sym}_file".to_sym do
      File.join metadata_path, sym.to_s
    end

    # @return [String] the data or nil if not set
    define_method :"load_#{sym}".to_sym do
      file = send :"#{sym}_file".to_sym
      File.read file if File.exist? file
    end

    # @param [String] the data to be saved
    define_method :"save_#{sym}".to_sym do |value|
      file = send :"#{sym}_file".to_sym
      tmp_file = "#{file}.tmp"
      open(tmp_file, 'w') { |io| io.write value}
      FileUtils.mv tmp_file, file
    end

  end

end

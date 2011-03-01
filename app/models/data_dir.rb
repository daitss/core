module DataDir

  PATHS = [
    :work',
    :stash',
    :submit',
    :disseminate',
    :dispatch',
    :profile',
    :nuke',
    :reports'
  ]

  PATHS.each do |sym|
    define_method :"#{sym}_path".to_sym do
      File.join DATA_DIR, sym.to_s
    end
  end

  def make_all

    Dir.chdir DATA_DIR do

      DATA_PATHS.each do |p|
        FileUtils.mkdir p.to_s
      end

    end

  end
  module_function :make_all

end

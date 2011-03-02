module DataDir

  PATHS = [
    :work,
    :stash,
    :submit,
    :disseminate,
    :dispatch,
    :profile,
    :nuke,
    :reports
  ]

  PATHS.each do |sym|
    m_sym = :"#{sym}_path".to_sym

    define_method m_sym do
      File.join DATA_DIR, sym.to_s
    end

    module_function m_sym
  end

  def make_all

    Dir.chdir DATA_DIR do

      PATHS.each do |p|
        FileUtils.mkdir p.to_s
      end

    end

  end
  module_function :make_all

end

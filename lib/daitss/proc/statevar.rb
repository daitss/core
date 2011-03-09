require 'fileutils'
require 'mixin/file'

module StateVar

  def state_var sym, options={}

    # make it readable
    attr_reader sym

    # the file that will maintain state
    filename = sym.to_s
    i_sym = "@#{sym}".to_sym

    # make the load function
    define_method :"load_#{sym}".to_sym do
      file = File.join @path, filename

      if File.exist? file
        data = File.lock(file, :shared => true) { Marshal.load File.read(file) }
        instance_variable_set i_sym, data
      else
        send :"reset_#{sym}".to_sym
      end

    end

    # make the save function
    define_method :"save_#{sym}".to_sym do
      file = File.join @path, filename
      tmp_file = "#{file}-#{$$}.tmp"
      data = instance_variable_get i_sym
      marsh = Marshal.dump data
      open(tmp_file, 'w') { |io| io.write marsh }

      FileUtils.touch(file)
      File.lock(file) { File.rename tmp_file, file }
    end

    # make the reset function
    define_method :"reset_#{sym}".to_sym do
      file = File.join @path, filename

      default = if options[:default]
                  options[:default].dup
                end

      instance_variable_set i_sym, default
      send :"save_#{sym}".to_sym
    end

  end

end

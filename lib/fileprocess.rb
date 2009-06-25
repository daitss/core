require 'service/error'

module FileProcess

  def process!

    begin
      describe unless described?
      plan unless planned?

      transformations.each do |t|
        t.perform!

        t.data do |io, fname| 
          new_file = add_file io, fname
          new_file.add_md :tech, t.metadata
          new_file.describe unless described?
        end

      end

    rescue ServiceError => e
      t = template_by_name 'per_file_error'
      s = t.result binding
      error_doc = XML::Parser.string(s).parse
      add_md :digiprov, error_doc
    end

  end

end
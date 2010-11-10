require 'daitss/proc/wip'

module Daitss

  class Wip

    JOURNAL_FILE = 'journal.yml'

    def journal_file
      File.join @path, JOURNAL_FILE
    end

    def tmp_journal_file
      journal_file + ".tmp"
    end

    def load_journal

      unless File.exist? journal_file
        @journal = {}
        save_journal
      else
        @journal = YAML.load_file journal_file
      end

    end

    def save_journal
      open(tmp_journal_file, 'w') { |io| io.write YAML.dump @journal }
      FileUtils.mv tmp_journal_file, journal_file
    end

    def step name

      if @journal[name]
        @journal[name]
      else
        m = {}
        m[:time] = Time.now
        yield
        m[:duration] = Time.now - m[:time]
        @journal[name] = m
        save_journal
        m
      end

    end

    def steps_descending

      @journal.sort do |a,b|
        a[1][:time] <=> b[1][:time]
      end

    end

  end

end

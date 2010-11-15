require 'daitss/proc/wip'

module Daitss

  class Wip

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

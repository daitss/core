require 'daitss/proc/wip'

module Daitss

  class Wip

    def step name

      if @journal[name]
        @journal[name]
      else
        m = {}
        m[:time] = Time.now
        m[:detail] = ""
        @journal[name] = m
        yield
        m[:duration] = Time.now - m[:time]

        save_journal
        m
      end

    end

    # add substep detail to an existing step
    def add_substep stepname, substep
        m = @journal[stepname]
        start_time = Time.now
        yield
        duration = "%4.2f" % (Time.now - start_time).to_f
        m[:detail] += "#{substep}:#{duration} | "
       
        #@journal[stepname] = m
        #save_journal
        #m

    end

    def steps_descending

      @journal.sort do |a,b|
        a[1][:time] <=> b[1][:time]
      end

    end

  end

end

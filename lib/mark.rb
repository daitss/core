require 'time'

class Mark
  attr_reader :start_time, :finish_time

  def Mark.parse s
    start, finish = s.split(' ').map { |s| Time.parse s }
    m = Mark.new

    m.instance_eval do
      @start_time = start
      @finish_time = finish
    end

    m
  end

  def initialize
    super
  end

  def start
    @start_time = Time.now
  end

  def finish
    raise "mark not started" unless @start_time
    @finish_time = Time.now
  end

  def duration
    raise "mark not started" unless @start_time
    raise "mark not finished" unless @finish_time
    @finish_time - @start_time
  end

  def to_s
    "#{@start_time.xmlschema 4} #{@finish_time.xmlschema 4}"
  end

  def eql? other
    to_s == other.to_s
  end
  alias_method :==, :eql?


end

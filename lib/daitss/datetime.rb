require 'date'

class DateTime

  # returns a string representation of the DateTime object
  #
  # if the object is ...
  # within the current day: '%I:%M %p'
  # within the current year: '%b %d'
  # anything else: '%D'
  def pragma
    now = DateTime.now

    if now.jd == self.jd
      self.strftime('%I:%M %p').downcase
    elsif now.year == self.year
      self.strftime '%b %d'
    else
     self.strftime '%D'
    end

  end

end

class Time

  def pragma
    now = Time.now

    if now.year == self.year and now.yday == self.yday
      self.strftime('%I:%M %p').downcase
    elsif now.year == self.year
      self.strftime '%b %d'
    else
     self.strftime '%D'
    end

  end

end

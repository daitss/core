def next_in_set set, regex
  
   taken = set.map do |e|

      if e =~ regex
        $1.to_i
      else
        -1
      end

    end      
    
    if taken.empty?
      0
    else
      taken.max + 1
    end

end

module Enumerable
  
  def next_in pattern
    next_in_set self, pattern
  end
  
end

def delta_stats
  puts '* * * delta stats * * * called from ' + caller.inspect
  stats = memory_stats(false)
  $old_stats ||= stats
  delta = {}
  ($old_stats.keys + stats.keys).each do |key|
    d = stats[key] - $old_stats[key] 
    delta[key] = d unless d == 0
  end
  show_stats delta
  $old_stats = stats
end

def memory_stats(show = true)
  stats = Hash.new { |h, k| h[k] = 0 }
  ObjectSpace.each_object do |o|
    stats[o.class] += 1
  end
  if show
    puts '* * * memory stats * * * called from ' + caller.inspect
    show_stats stats
  end
  stats
end

def show_stats(stats)
  stats.sort_by { |s| s[1] }.reverse.each do |stat|
    puts stat.inspect
  end
end

by_freq = ARGF.each_line.map { |l| l.strip.chars }.transpose.map(&:tally).map { |f|
  f.to_a.sort_by(&:last).map(&:first)
}
puts %i(last first).map { |s| by_freq.map(&s).join }

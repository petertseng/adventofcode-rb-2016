by_freq = ARGF.map { |l| l.strip.chars }.transpose.map(&:tally).map { |f|
  f.to_a.sort_by(&:last).map(&:first).freeze
}.freeze
puts %i(last first).map { |s| by_freq.map(&s).join }

# Assumes without checking that input intervals are sorted by start time.
def min_unblock(intervals)
  unblocked = 0
  intervals.each { |min, max|
    return unblocked if min > unblocked
    unblocked = [unblocked, max + 1].max
  }
end

# Assumes without checking that input intervals are sorted by start time.
def merge(intervals)
  prev_min, prev_max = intervals.first
  intervals.each_with_object([]) { |r, merged|
    min, max = r
    if min > prev_max
      merged << [prev_min, prev_max]
      prev_min, prev_max = r
    else
      prev_max = [prev_max, max].max
    end
  } << [prev_min, prev_max]
end

ranges = ARGF.each_line.map { |l|
  # min, max
  l.split(?-).map(&method(:Integer)).freeze
}.sort.freeze

puts min_unblock(ranges)
puts 2 ** 32 - merge(ranges).sum { |min, max| (max - min + 1) }

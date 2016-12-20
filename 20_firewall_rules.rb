def min_unblock(intervals)
  unblocked = 0
  loop {
    blockers = intervals.select { |min, max| (min..max).include?(unblocked) }
    return unblocked if blockers.empty?
    unblocked = blockers.map(&:last).max + 1
  }
end

# Assumes without checking that input intervals are sorted by start time.
def merge(intervals, merge_adjacent: true)
  prev_min, prev_max = intervals.first
  (intervals.each_with_object([]) { |r, merged|
    min, max = r
    if min > prev_max + (merge_adjacent ? 1 : 0)
      merged << [prev_min, prev_max].freeze
      prev_min, prev_max = r
    else
      prev_max = [prev_max, max].max
    end
  } << [prev_min, prev_max].freeze).freeze
end

ranges = ARGF.map { |l|
  # min, max
  l.split(?-).map(&method(:Integer)).freeze
}.sort.freeze

puts min_unblock(ranges)
puts 2 ** 32 - merge(ranges).sum { |min, max| (max - min + 1) }

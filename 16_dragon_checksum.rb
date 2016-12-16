lengths = if (larg = ARGV.find { |a| a.start_with?('-l') })
  ARGV.delete(larg)
  larg[2..-1].split(?,).map(&method(:Integer))
else
  [272, 35651584]
end.freeze

input = (!ARGV.empty? && (v = ARGV.find { |arg| arg.match?(/^[01]+$/)}) ? v : ARGF.read).freeze
bit = {?1 => true, ?0 => false}.freeze
orig_a = input.each_char.map { |c| bit.fetch(c) }.freeze

module Dragon
  module_function
  # ones in the inclusive one-indexed range [left, right]
  def ones(left, right)
    # Powers of two are guaranteed zero.
    # Find the largest one no larger than the right end.
    zero = 1 << Math.log2(right).floor

    if left > zero
      # we are completely on one end of the power of two.
      len = right - left + 1
      return len - ones(zero * 2 - right, zero * 2 - left)
    end

    # we straddle the power of two.
    left_of_zero = zero - left
    right_of_zero = right - zero
    overlap = [left_of_zero, right_of_zero].min
    excess = (left_of_zero - right_of_zero).abs

    if left_of_zero > right_of_zero
      overlap + ones(left, zero - 1 - overlap)
    elsif left_of_zero < right_of_zero
      overlap + excess - ones(zero * 2 - right, left - 1)
    else
      overlap
    end
  end
end

lengths.each { |disk|
  # The disk pattern is:
  # input, dragon, input reversed and negated, dragon, repeat
  a = orig_a
  a_rev = a.reverse.map(&:!).freeze

  # chunk_size: the largest power of 2 that divides disk.
  # e.g.   272 is 100010000
  #        271 is 100001111
  #       ~271 is  11110000
  # 272 & ~271 is     10000
  chunk_size = disk & ~(disk - 1)
  sum_size = disk / chunk_size

  buf = []
  dragons_total = 0

  # each character in the final checksum
  # corresponds to `chunk_size` consecutive characters on disk.
  puts sum_size.times.map {
    dragons_before = dragons_total
    ones = 0
    dragons = 0

    count_from_buffer = ->(n) {
      taken = buf.shift(n)
      ones += taken.count(true)
      dragons += taken.count(:dragon)
    }

    # Anything left in the buffer from last time?
    take_from_buffer = [buf.size, chunk_size].min
    remaining = chunk_size - take_from_buffer
    count_from_buffer[take_from_buffer]

    # How many full ADBD groups will we have?
    full_adbds, remaining = remaining.divmod((a.size + 1) * 2)
    dragons += full_adbds * 2
    # The number of ones in a + a_rev... is obviously a.size.
    ones += a.size * full_adbds

    if remaining > 0
      buf.concat(a)
      buf << :dragon
      buf.concat(a_rev)
      buf << :dragon
      count_from_buffer[remaining]
    end

    dragons_total += dragons
    ones += Dragon.ones(dragons_before + 1, dragons_total) if dragons > 0
    1 - ones % 2
  }.join
}

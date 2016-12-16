lengths = if (larg = ARGV.find { |a| a.start_with?('-l') })
  ARGV.delete(larg)
  larg[2..-1].split(?,).map(&method(:Integer))
else
  [272, 35651584]
end.freeze

input = (!ARGV.empty? && (v = ARGV.find { |arg| arg.match?(/^[01]+$/)}) ? v : ARGF.read).freeze
bit = {?1 => true, ?0 => false}.freeze
orig_a = input.each_char.map { |c| bit.fetch(c) }.freeze

lengths.each { |disk|
  # The disk pattern is:
  # input, dragon, input reversed and negated, dragon, repeat
  a = orig_a
  a_rev = a.reverse.map(&:!).freeze

  dragons = []
  until dragons.size * (a.size + 1) >= disk
    dragons += [false] + dragons.reverse.map(&:!)
  end

  # chunk_size: the largest power of 2 that divides disk.
  # e.g.   272 is 100010000
  #        271 is 100001111
  #       ~271 is  11110000
  # 272 & ~271 is     10000
  chunk_size = disk & ~(disk - 1)
  sum_size = disk / chunk_size

  buf = []

  # each character in the final checksum
  # corresponds to `chunk_size` consecutive characters on disk.
  puts sum_size.times.map {
    # Anything left in the buffer from last time?
    take_from_buffer = [buf.size, chunk_size].min
    remaining = chunk_size - take_from_buffer
    ones = buf.shift(take_from_buffer).count(true)

    # How many full ADBD groups will we have?
    full_adbds, remaining = remaining.divmod((a.size + 1) * 2)
    # Count all the ones in the dragons.
    ones += dragons.shift(full_adbds * 2).count(true)
    # The number of ones in a + a_rev... is obviously a.size.
    ones += a.size * full_adbds

    if remaining > 0
      buf.concat(a)
      buf << dragons.shift
      buf.concat(a_rev)
      buf << dragons.shift
      ones += buf.shift(remaining).count(true)
    end

    1 - ones % 2
  }.join
}

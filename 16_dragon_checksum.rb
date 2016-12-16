test = ARGV.delete('-t')

input = !ARGV.empty? && ARGV.first.match?(/^[01]+$/) ? ARGV.first : ARGF.read

(test ? [20] : [272, 35651584]).each { |disk|
  # The disk pattern is:
  # input, dragon, input reversed and negated, dragon, repeat
  a = input.each_char.map { |c| c == ?1 }.freeze
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
    while buf.size < chunk_size
      buf.concat(a)
      buf << dragons.shift
      buf.concat(a_rev)
      buf << dragons.shift
    end

    chunk = buf.shift(chunk_size)
    1 - chunk.count(true) % 2
  }.join
}

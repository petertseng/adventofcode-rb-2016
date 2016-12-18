# Store rows in blocks of this size.
# 1 = trap, 0 = safe.
# Within each block, characters on the left are the most significant bits.
BLOCK = 10

# We'll pre-compute every single block of 12 -> 10,
# since 4096 entries in a table is easy.
RULE = (0...(1 << BLOCK + 2)).map { |i|
  (0...BLOCK).select { |j|
    (i >> j) & 1 != (i >> j + 2) & 1
  }.map { |j| 1 << j }.reduce(0, :|)
}.freeze

SAFE_COUNT = (0...(1 << BLOCK)).map { |i| BLOCK - i.to_s(2).count(?1) }.freeze

rows = begin
  arg = ARGV.find { |x| x.start_with?('-n') }
  arg && Integer(ARGV.delete(arg)[2..-1])
end

input = (!ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read).freeze

bit = {?^ => 1, ?. => 0}.freeze
prev_row = input.each_char.each_slice(BLOCK).map { |slice|
  slice.reduce(0) { |i, c| i << 1 | bit.fetch(c) }
}

safe = prev_row.sum { |block| SAFE_COUNT[block] }

current_row = Array.new(prev_row.size)

(rows ? [rows - 1] : [39, 399960]).each { |n|
  n.times {
    window = 0
    current_row.size.times { |i|
      window = (window << BLOCK | prev_row[i] << 1 | (prev_row[i + 1] || 0) >> BLOCK - 1) & (1 << BLOCK + 2) - 1
      current_row[i] = RULE[window]
      safe += SAFE_COUNT[current_row[i]]
    }
    prev_row, current_row = [current_row, prev_row]
  }
  puts safe
}

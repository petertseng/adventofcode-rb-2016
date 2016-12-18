rows = begin
  arg = ARGV.find { |x| x.start_with?('-n') }
  arg && Integer(ARGV.delete(arg)[2..-1])
end

input = (!ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read).freeze

bit = {?^ => 1, ?. => 0}.freeze
row = input.each_char.reduce(0) { |i, c| i << 1 | bit.fetch(c) }
mask = 2 ** input.size - 1

total = input.size
traps = row.to_s(2).count(?1)

(rows ? [rows - 1] : [39, 399960]).each { |n|
  n.times {
    row = ((row << 1) ^ (row >> 1)) & mask
    traps += row.to_s(2).count(?1)
  }
  total += n * input.size
  puts total - traps
}

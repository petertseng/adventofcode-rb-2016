rows = begin
  arg = ARGV.find { |x| x.start_with?('-n') }
  arg && Integer(ARGV.delete(arg)[2..-1])
end

input = (!ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read).freeze

# 1 = trap, 0 = safe.
# Integers rather than booleans will help us later.
bit = {?^ => 1, ?. => 0}.freeze
prev_row = input.each_char.map { |c| bit.fetch(c) }
safe = prev_row.count(0)

current_row = Array.new(prev_row.size)

(rows ? [rows - 1] : [39, 399960]).each { |n|
  n.times {
    window = prev_row[0]
    current_row.size.times { |i|
      window = (window << 1 | (prev_row[i + 1] || 0)) & 7
      is_trap = [1, 4, 3, 6].include?(window)
      safe += 1 unless is_trap
      current_row[i] = is_trap ? 1 : 0
    }
    prev_row, current_row = [current_row, prev_row]
  }
  puts safe
}

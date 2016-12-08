require_relative 'gen_08/letters'

HEIGHT = 6

msg = ARGV.join(' ').freeze

letters = msg.each_char.map { |c| LETTERS.fetch(c) }.freeze

# Strategy: For each row, generate the rightmost pixel of that row, then shift it.
# Generate the second-rightmost pixel of that row, then shift it.
# etc.

rows = (0...HEIGHT).map { |row|
  cells = letters.map { |l| l[row] }.join.each_char.map { |c| c != ' ' }
  stripped = cells.drop_while(&:!).reverse.drop_while(&:!)
  {
    leftmost_gap: cells.take_while(&:!).size,
    # [T, T, F, F, T, F, T] -> [[T], [T], [F, F, T], [F, T]]
    # This lets us determine how many falses are between each true.
    # drop 1 because the first chunk is the rightmost cell,
    # and we don't need to leave a gap to its right
    gaps: stripped.slice_after(true).drop(1).map(&:size).freeze,
  }.freeze
}.freeze

rows.map { |r| r[:gaps].size }.max.times { |i|
  puts 'rect 1x6'
  rows.each_with_index { |row, r|
    next unless (gap = row[:gaps][i])
    puts "rotate row y=#{r} by #{gap}"
  }
}

puts 'rect 1x6'
rows.each_with_index { |row, r|
  next if (gap = row[:leftmost_gap]) == 0
  puts "rotate row y=#{r} by #{gap}"
}

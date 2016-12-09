require_relative 'gen_08/letters'

FIRST_N_ROWS = begin
  arg = ARGV.find { |x| x.start_with?('-O') }
  arg ? Integer(ARGV.delete(arg)[2..-1]) : 2
end
HEIGHT = 6

msg = ARGV.join(' ').freeze
WIDTH = 5 * msg.size

letters = msg.each_char.map { |c| LETTERS.fetch(c) }.freeze
cells = (0...HEIGHT).map { |row|
  letters.map { |l| l[row] }.join.each_char.map { |c| c != ' ' }.freeze
}.freeze

# Strategy: For each row, generate the rightmost pixel of that row, then shift it.
# Generate the second-rightmost pixel of that row, then shift it.
# etc.

rows = cells.map { |row|
  stripped = row.drop_while(&:!).reverse.drop_while(&:!)
  {
    leftmost_gap: row.take_while(&:!).size,
    # [T, T, F, F, T, F, T] -> [[T], [T], [F, F, T], [F, T]]
    # This lets us determine how many falses are between each true.
    # drop 1 because the first chunk is the rightmost cell,
    # and we don't need to leave a gap to its right
    gaps: stripped.slice_after(true).drop(1).map(&:size),
  }.freeze
}.freeze

# FIRST, optimise by filling the first two rows.
# We'll use any columns that should be vacant to fill lower rows.
# This section is NOT STRICTLY NECESSARY
# (the algorithm still works without it)
# but it is an interesting optimisation.

if FIRST_N_ROWS > 0
  rotate_row = ->(row, current:) {
    want = rows[row][:gaps].shift || rows[row][:leftmost_gap]
    puts "rotate row y=#{row} by #{(want - current) % WIDTH}" if want != current
  }

  sizes = rows.map { |r| r[:gaps].size + 1 }
  prev_index = Array.new(rows.size)
  align_row = ->(row, to_receive:) {
    if (prev = prev_index[row])
      current_offset = prev - to_receive
      rotate_row[row, current: current_offset]
    end
    sizes[row] -= 1
    prev_index[row] = to_receive
  }

  positions_to_clear = (0...FIRST_N_ROWS).map { |r|
    (0...WIDTH).reject { |i| cells[r][i] }.map { |x|
      (x - rows[r][:leftmost_gap]) % WIDTH
    }.sort
  }.freeze

  puts "rect #{WIDTH}x#{FIRST_N_ROWS}"

  case FIRST_N_ROWS
  when 2
    WIDTH.times { |from_left|
      pos = WIDTH - 1 - from_left
      clears = positions_to_clear.map { |ptc| ptc.last == pos }
      case clears
      when [true, true]
        # Vacate both. Find best pair to give it to.
        largest_other = (2...HEIGHT).max_by { |i| sizes[i] }
        neighbour = case largest_other
                    when 2; 3
                      # Middle rows always prefer each other,
                      # since edge rows are forced in more situations.
                    when 3; 4
                    when 4; 3
                    when 5; 4
                    end
        [largest_other, neighbour].each { |row| align_row[row, to_receive: pos] }
        puts "rotate column x=#{pos} by #{[largest_other, neighbour].min}"
      when [true, false]
        # We can only shift it down 1 and give it to row 2.
        align_row[2, to_receive: pos]
        puts "rotate column x=#{pos} by 1"
      when [false, true]
        # We can only shift it up 1 and give it to row (HEIGHT - 1).
        align_row[HEIGHT - 1, to_receive: pos]
        puts "rotate column x=#{pos} by #{HEIGHT - 1}"
      when [false, false]
        # Nothing.
      end

      positions_to_clear.zip(clears) { |ptc, clear| ptc.pop if clear }
    }
  when 1
    positions_to_clear.first.reverse_each { |pos|
      largest_other = (1...HEIGHT).max_by { |i| sizes[i] }
      align_row[largest_other, to_receive: pos]
      puts "rotate column x=#{pos} by #{largest_other}"
    }
  else raise "Optimisation level #{FIRST_N_ROWS} unsupported"
  end

  (FIRST_N_ROWS...HEIGHT).each { |r|
    next unless (current_offset = prev_index[r])
    rotate_row[r, current: current_offset]
  }

  FIRST_N_ROWS.times { |i| rows[i][:gaps].clear }
end

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

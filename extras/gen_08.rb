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
    want = rows[row][:gaps].shift || (raise "Overflowed row #{row}")
    puts "rotate row y=#{row} by #{(want - current) % WIDTH}" if want != current
  }

  sizes = rows.map { |r| r[:gaps].size + 1 }
  prev_index = Array.new(rows.size)
  align_row = ->(row, to_receive:) {
    if (prev = prev_index[row])
      current_offset = prev - to_receive
      rotate_row[row, current: current_offset]
    end
    prev_index[row] = to_receive
  }

  best_by_gap = ->(choices, pos, if_present, if_absent) {
    choices.max_by { |choice|
      if (prev = prev_index[choice])
        current_offset = prev - pos
        want = rows[choice][:gaps].first || 1.0 / 0.0
        if current_offset == want
          [3, if_present[choice]]
        elsif current_offset > want
          # too low can fix itself (pos will decrease, current_offset will increase, want stays the same)
          # too high can't, so we might as well shift on the too-high row if possible.
          [1, if_present[choice]]
        else
          [0, if_present[choice]]
        end
      else
        [2, if_absent[choice]]
      end
    }
  }

  positions_to_clear = (0...FIRST_N_ROWS).map { |r|
    (0...WIDTH).reject { |i| cells[r][i] }.map { |x|
      (x - rows[r][:leftmost_gap]) % WIDTH
    }.sort
  }.freeze

  puts "rect #{WIDTH}x#{FIRST_N_ROWS}"

  case FIRST_N_ROWS
  when 2
    WIDTH.times.each_with_object([]) { |from_left, sends|
      pos = WIDTH - 1 - from_left
      clears = positions_to_clear.map { |ptc| ptc.last == pos }
      case clears
      when [true, true]
        # Vacate both. Find best pair to give it to later.
        sends << {pos: pos, receivers: :unknown}
      when [true, false]
        # We can only shift it down 1 and give it to row 2.
        sends << {pos: pos, shift: 1, receivers: [2].freeze}.freeze
        sizes[2] -= 1
      when [false, true]
        # We can only shift it up 1 and give it to row (HEIGHT - 1).
        sends << {pos: pos, shift: HEIGHT - 1, receivers: [HEIGHT - 1].freeze}.freeze
        sizes[HEIGHT - 1] -= 1
      when [false, false]
        # Nothing.
      end

      positions_to_clear.zip(clears) { |ptc, clear| ptc.pop if clear }
    }.each { |send|
      if send[:receivers] == :unknown
        largest_other = (2...HEIGHT).max_by { |i| sizes[i] }
        choices = case largest_other
                  when 2; [3]
                  when 3; [4, 2]
                  when 4; [3, 5]
                  when 5; [4]
                  end
        neighbour = best_by_gap[choices, send[:pos], sizes, sizes]
        receivers = [largest_other, neighbour].sort.freeze
        receivers.each { |row| sizes[row] -= 1 }
        send[:shift] = receivers.min
        send[:receivers] = receivers
      end
      send[:receivers].each { |row| align_row[row, to_receive: send[:pos]] }
      puts "rotate column x=#{send[:pos]} by #{send[:shift]}"
    }
  when 1
    positions_to_clear = positions_to_clear.first.reverse
    cells_needed = positions_to_clear.size.times.with_object(Hash.new(0)) { |_, freq|
      largest_other = (1...HEIGHT).max_by { |i| sizes[i] }
      freq[largest_other] += 1
      sizes[largest_other] -= 1
    }
    positions_to_clear.each { |pos|
      choices = (1...HEIGHT).select { |r| cells_needed[r] > 0 }
      # For reasons I can't explain, this seemed to do the best.
      # It did better than:
      # * number of cells needed
      # * number of immediately-next gaps that match with positions_to_clear
      # Maybe it's just a peculiarity of the inputs I test on?
      remaining_gaps = choices.to_h { |choice|
        [choice, rows[choice][:gaps].drop(1).map { |x| -x }]
      }
      receiver = best_by_gap[choices, pos, remaining_gaps, cells_needed]
      cells_needed[receiver] -= 1
      align_row[receiver, to_receive: pos]
      puts "rotate column x=#{pos} by #{receiver}"
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

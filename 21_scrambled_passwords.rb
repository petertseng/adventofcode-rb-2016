def apply(instructions, input, undo: false)
  instructions.reduce(input.dup) { |pw, (cmd, *args)|
    case cmd
    when :swap_letter
      # Undo == do
      pw.tr(args.join, args.join.reverse)
    when :swap_position
      # Undo == do
      i, j = args
      pw[i], pw[j] = [pw[j], pw[i]]
      pw
    when :rotate_right
      pw.chars.rotate(args[0] * (undo ? 1 : -1)).join
    when :rotate_left
      pw.chars.rotate(args[0] * (undo ? -1 : 1)).join
    when :rotate_based
      i = pw.index(args[0])
      if undo
        # rotate_based needs the most work to undo.
        # pos shift newpos
        #   0     1      1
        #   1     2      3
        #   2     3      5
        #   3     4      7
        #   4     6      2
        #   5     7      4
        #   6     8      6
        #   7     9      0
        # all odds have a clear pattern, all evens have a clear pattern...
        # except 0, which we'll just special-case.
        rot = i / 2 + (i % 2 == 1 || i == 0 ? 1 : 5)
      else
        rot = -(i + 1 + (i >= 4 ? 1 : 0))
      end
      pw.chars.rotate(rot).join
    when :reverse_positions
      # Undo == do
      c = pw.chars
      s, e = args
      c[s..e] = c[s..e].reverse
      c.join
    when :move_position
      from, to = undo ? args.reverse : args
      c = pw.chars
      ch = c.delete_at(from)
      c.insert(to, ch)
      c.join
    else raise "Unknown command #{cmd} #{args}"
    end
  }
end

instructions = ARGF.map { |l|
  words = l.split
  # All the args are either single letters or single digits.
  [words[0..1].join(?_).to_sym] + words.select { |w| w.size == 1 }.map { |w|
    w.match?(/\d+/) ? Integer(w) : w
  }.freeze
}.freeze

puts apply(instructions, 'abcdefgh')
puts apply(instructions.reverse, 'fbgdceah', undo: true)

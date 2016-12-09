WIDTH = begin
  arg = ARGV.find { |x| x.start_with?('-w') }
  arg ? Integer(ARGV.delete(arg)[2..-1]) : 50
end
HEIGHT = 6

physical_screen = Array.new(HEIGHT) { Array.new(WIDTH, false) }.freeze
virtual_screen = Array.new(HEIGHT) { |r|
  Array.new(WIDTH) { |c| ->{ physical_screen[r][c] = true } }
}.freeze

ARGF.each_line.reverse_each { |l|
  words = l.split
  case words[0]
  when 'rect'
    cols, rows = words[1].split(?x).map(&method(:Integer))
    rows.times { |r|
      cols.times { |c| virtual_screen[r][c][] }
    }
  when 'rotate'
    idx = Integer(words[2][/\d+/])
    # we're going backwards so we have to rotate backwards too!
    # positive amount is left/up, which is indeed backwards.
    amt = Integer(words[4][/\d+/])
    case words[1]
    when 'row'
      virtual_screen[idx].rotate!(amt)
    when 'column'
      rotated = virtual_screen.map { |row| row[idx] }.rotate(amt)
      virtual_screen.zip(rotated) { |row, pixel| row[idx] = pixel }
    else raise "Rotate #{words[1]} unknown"
    end
  else raise "Operation #{words[0]} unknown"
  end
}

puts physical_screen.sum { |row| row.count(true) }
physical_screen.each { |r|
  puts r.map { |cell| cell ? ?# : ' ' }.join
}

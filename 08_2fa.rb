WIDTH = begin
  arg = ARGV.find { |x| x.start_with?('-w') }
  arg ? Integer(ARGV.delete(arg)[2..-1]) : 50
end
HEIGHT = 6

screen = Array.new(HEIGHT) { Array.new(WIDTH, false) }.freeze

ARGF.each_line { |l|
  words = l.split
  case words[0]
  when 'rect'
    cols, rows = words[1].split(?x).map(&method(:Integer))
    rows.times { |r|
      cols.times { |c| screen[r][c] = true }
    }
  when 'rotate'
    idx = Integer(words[2][/\d+/])
    amt = -Integer(words[4][/\d+/])
    case words[1]
    when 'row'
      screen[idx].rotate!(amt)
    when 'column'
      rotated = screen.map { |row| row[idx] }.rotate(amt)
      screen.zip(rotated) { |row, pixel| row[idx] = pixel }
    else raise "Rotate #{words[1]} unknown"
    end
  else raise "Operation #{words[0]} unknown"
  end
}

puts screen.sum { |row| row.count(true) }
screen.each { |r|
  puts r.map { |cell| cell ? ?# : ' ' }.join
}

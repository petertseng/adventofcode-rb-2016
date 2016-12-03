parts = [{
  keypad: [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ].map(&:freeze).freeze,
  admit: ->(row, col) { [row, col].all? { |c| 0 <= c && c <= 2 } }
}, {
  keypad: [
    [nil, nil,  1, nil, nil],
    [nil,   2,  3,   4, nil],
    [  5,   6,  7,   8,   9],
    [nil,  :A, :B,  :C, nil],
    [nil, nil, :D, nil, nil],
  ].map(&:freeze).freeze,
  admit: ->(row, col) { (col - 2).abs + (row - 2).abs <= 2 }
}].map(&:freeze).freeze

START_AT = 5

input = ARGF.readlines.map(&:freeze).freeze

puts parts.map { |part|
  keypad = part[:keypad].map(&:freeze).freeze
  admit = part[:admit]

  row = keypad.index { |x| x.include?(START_AT) }
  pos = [row, keypad[row].index(START_AT)]

  try = ->(coord:, dir:) {
    pos[coord] += dir
    pos[coord] -= dir unless admit[*pos]
  }

  input.map { |l|
    l.chomp.each_char { |c|
      case c
      when ?L; try[coord: 1, dir: -1]
      when ?R; try[coord: 1, dir:  1]
      when ?U; try[coord: 0, dir: -1]
      when ?D; try[coord: 0, dir:  1]
      else raise "bad char #{c}"
      end
    }
    keypad[pos[0]][pos[1]]
  }.join
}

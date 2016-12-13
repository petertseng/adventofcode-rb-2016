require 'io/console'

WIDTH = 50
HEIGHT = 6
AGES = %i(old new).freeze

TAMPER = ARGV.delete('-t')

module TwoFactorAuth
  refine Hash do
    def swap!
      swap = self[:old]
      self[:old] = self[:new]
      self[:new] = swap
    end
  end

  refine Array do
    def apply_move(op, *args, type:)
      case op
      when :rect
        cols, rows = type == :flipped ? args.reverse : args
        rows.times { |r|
          cols.times { |c| self[r][c] += 1 }
        }
      when :row
        row, amt = args
        self[row].rotate!(-amt)
      when :column
        col, amt = args
        rotated = (0...HEIGHT).map { |r| self[r][col] }.rotate(-amt)
        HEIGHT.times { |r| self[r][col] = rotated[r] }
      else raise "unknown op #{op}"
      end
    end

    def undo_move(op, *args, type:)
      case op
      when :rect
        cols, rows = type == :flipped ? args.reverse : args
        rows.times { |r|
          cols.times { |c| self[r][c] -= 1 }
        }
      else apply_move(op, args[0], -args[1], type: type)
      end
    end
  end
end

class Boards
  attr_reader :boards

  using TwoFactorAuth

  def initialize(input)
    @input = input.map { |inst|
      words = inst.split
      case words[0]
      when 'rect'; [:rect] + words[1].split(?x).map(&method(:Integer))
      when 'rotate'
        [
          words[1].to_sym,
          Integer(words[2][/\d+/]),
          Integer(words[4][/\d+/]),
        ]
      else raise "Operation #{words[0]} unknown"
      end.freeze
    }.freeze
    @pc = 0
    @boards = (TAMPER ? %i(flipped unflipped) : %i(unflipped)).to_h { |type| [type,
      AGES.to_h { |age| [age, Array.new(HEIGHT) { Array.new(WIDTH, 0) }] }
    ]}.freeze

    @boards.each { |type, board| board[:new].apply_move(*@input[0], type: type) }
  end

  def advance
    return if @pc == @input.size - 1
    old_pc = @pc
    @pc += 1
    @boards.each { |type, board|
      board[:old].apply_move(*@input[old_pc], type: type)
      board[:new].apply_move(*@input[@pc], type: type)
    }
  end

  def undo
    return if @pc == 0
    old_pc = @pc
    @pc -= 1
    @boards.each { |type, board|
      board[:old].undo_move(*@input[@pc], type: type)
      board[:new].undo_move(*@input[old_pc], type: type)
    }
  end

  def to_s
    inst = @input[@pc]
    "Move #{@pc}: #{inst}\n" + AGES.map { |age|
      other_age = (AGES - [age]).first
      # kind hacky - place the type in front of the row.
      boards = @boards.map { |k, v| v[age].map { |row| [k] + row } }
      boards[0].zip(*boards[1..-1]).map.with_index { |boards_rows, r|
        row_important = inst[0] == :row && inst[1] == r
        boards_rows.map { |type_and_row|
          type, *row = type_and_row
          row.map.with_index { |cell, c|
            col_important = inst[0] == :column && inst[1] == c
            rect_important = inst[0] == :rect && @boards[type][other_age][r][c] > 0 != cell > 0
            important = row_important || col_important || rect_important
            cell > 0 ? (important ? "\e[1m#\e[0m" : ?#) : ' '
          }.join
        }.join(' | ')
      }.join("\n")
    }.join("\n#{?- * (WIDTH * @boards.size + 3)}\n")
  end
end

input = (ARGV.empty? ? DATA : ARGF).readlines
boards = Boards.new(input)
puts boards

while (c = STDIN.getch)
  case c
  when "\u0003", ?q; exit 0
  when ?l
    boards.advance
    puts boards
  when ?j
    10.times { boards.advance }
    puts boards
  when ?k
    10.times { boards.undo }
    puts boards
  when ?h
    boards.undo
    puts boards
  else
  end
end

__END__
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 4
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 3
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 3
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 15
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 9
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 1
rect 2x1
rotate column x=1 by 4
rotate row y=4 by 24
rect 2x1
rotate column x=1 by 4
rotate row y=4 by 4
rect 2x1
rotate column x=1 by 4
rotate row y=4 by 7
rect 2x1
rotate column x=1 by 4
rotate row y=4 by 11
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 6
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 5
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 4
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 13
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 2
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 1
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 2
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 1
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 12
rect 2x1
rotate column x=1 by 3
rotate row y=3 by 49
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 3
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 1
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 3
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 3
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 4
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 4
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 1
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 8
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 17
rect 2x1
rotate column x=1 by 2
rotate row y=2 by 49
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 34
rotate column x=35 by 2
rect 2x1
rotate column x=1 by 4
rotate row y=4 by 34
rotate column x=35 by 2
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 34
rotate column x=35 by 2
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 32
rotate column x=33 by 2
rect 2x1
rotate column x=1 by 5
rotate row y=5 by 32
rotate column x=33 by 2
rect 2x1
rotate column x=1 by 4
rotate row y=4 by 3
rotate column x=4 by 2
rect 2x1
rotate row y=1 by 4
rotate column x=4 by 4
rotate column x=1 by 4
rotate row y=4 by 38
rotate column x=39 by 2
rect 2x1
rotate row y=1 by 2
rotate column x=2 by 4
rotate column x=1 by 5
rotate row y=5 by 38
rotate column x=39 by 2
rect 2x1
rotate row y=1 by 5
rotate column x=5 by 4
rotate column x=1 by 5
rotate row y=5 by 38
rotate column x=39 by 2
rect 2x1
rotate row y=1 by 48
rotate column x=48 by 4
rotate row y=5 by 2
rotate column x=1 by 5
rotate row y=5 by 17
rotate column x=18 by 2
rect 2x1
rotate row y=1 by 3
rotate column x=3 by 4
rotate column x=1 by 5
rotate row y=5 by 20
rotate column x=21 by 2
rect 2x1
rotate row y=1 by 11
rotate column x=11 by 4
rotate column x=1 by 4
rotate row y=4 by 5
rotate column x=6 by 2
rect 2x1
rotate row y=1 by 8
rotate column x=8 by 4
rotate column x=1 by 5
rotate row y=5 by 5
rotate column x=6 by 2
rect 2x1
rotate row y=1 by 32
rotate column x=32 by 3
rotate column x=1 by 5
rotate row y=5 by 7
rotate column x=8 by 2
rect 2x1
rotate row y=1 by 11
rotate column x=11 by 3
rotate column x=1 by 4
rotate row y=4 by 14
rotate column x=15 by 2
rect 2x1
rotate row y=1 by 15
rotate column x=15 by 3
rotate column x=1 by 5
rotate row y=5 by 9
rotate column x=10 by 2
rect 2x1
rotate row y=1 by 5
rotate column x=5 by 3
rotate column x=1 by 4
rotate row y=4 by 21
rotate column x=22 by 2
rect 2x1
rotate row y=1 by 23
rotate column x=23 by 2
rotate column x=1 by 4
rotate row y=4 by 21
rotate column x=22 by 2
rect 2x1
rotate row y=1 by 23
rotate column x=23 by 2
rotate column x=1 by 4
rotate row y=4 by 21
rotate column x=22 by 2
rect 2x1
rotate row y=1 by 22
rotate column x=22 by 1
rotate column x=1 by 5
rotate row y=5 by 4
rotate column x=5 by 2
rect 2x1
rotate row y=1 by 22
rotate column x=22 by 2
rotate column x=1 by 5
rotate row y=5 by 2
rotate column x=3 by 2
rect 2x1
rotate row y=1 by 20
rotate column x=20 by 2
rotate column x=1 by 5
rotate row y=5 by 6
rotate column x=7 by 2
rect 2x1
rotate row y=1 by 5
rotate column x=5 by 2
rotate column x=1 by 4
rotate row y=4 by 46
rotate column x=47 by 2
rect 2x1
rotate row y=1 by 47
rotate column x=47 by 1
rotate column x=1 by 4
rotate row y=4 by 4
rotate column x=5 by 2
rect 2x1
rotate row y=1 by 47
rotate column x=47 by 1
rotate column x=1 by 5
rotate row y=5 by 4
rotate column x=5 by 2
rect 2x1
rotate row y=1 by 2
rotate column x=1 by 5
rotate row y=5 by 1
rotate column x=2 by 2
rect 2x1
rotate row y=1 by 45
rotate column x=45 by 1
rotate column x=1 by 1
rect 2x1
rotate row y=1 by 36
rotate column x=36 by 1
rotate column x=1 by 5
rotate row y=5 by 1
rotate column x=2 by 2
rect 2x1
rotate row y=1 by 32
rotate column x=1 by 4
rotate row y=4 by 31
rotate column x=32 by 2
rect 2x1
rotate row y=1 by 32
rotate column x=32 by 5
rotate column x=1 by 4
rotate row y=4 by 31
rotate column x=32 by 2
rect 2x1
rotate row y=1 by 32
rotate column x=32 by 1
rotate column x=1 by 4
rotate row y=4 by 44
rotate column x=45 by 2
rect 2x1
rotate row y=1 by 28
rotate column x=28 by 1
rotate column x=1 by 4
rotate row y=4 by 44
rotate column x=45 by 2
rect 2x1
rotate row y=1 by 25
rotate column x=25 by 1
rotate column x=1 by 4
rotate row y=4 by 44
rotate column x=45 by 2
rect 2x1
rotate row y=1 by 25
rotate column x=25 by 1
rotate column x=1 by 4
rotate row y=4 by 37
rotate column x=38 by 2
rect 2x1
rotate row y=1 by 25
rotate column x=25 by 1
rotate column x=1 by 4
rotate row y=4 by 37
rotate column x=38 by 2
rect 2x1
rotate row y=1 by 28
rotate column x=1 by 4
rotate row y=4 by 35
rotate column x=36 by 2
rect 2x1
rotate row y=1 by 1
rotate column x=1 by 4
rotate row y=4 by 35
rotate column x=36 by 2
rect 2x1
rotate row y=1 by 2
rotate column x=1 by 4
rotate row y=4 by 33
rotate column x=34 by 2
rect 2x1
rotate row y=1 by 5
rotate column x=1 by 4
rotate row y=4 by 33
rotate column x=34 by 2
rect 2x1
rotate row y=1 by 11
rotate column x=1 by 4
rotate row y=4 by 22
rotate column x=23 by 2
rect 2x1
rotate row y=1 by 1
rotate column x=1 by 4
rotate row y=4 by 15
rotate column x=16 by 2
rect 2x1
rotate row y=1 by 45
rotate column x=45 by 5
rotate column x=1 by 4
rotate row y=4 by 7
rotate column x=8 by 2
rect 2x1
rotate row y=1 by 44
rotate column x=44 by 5
rotate column x=1 by 4
rotate row y=4 by 7
rotate column x=8 by 2
rect 2x1
rotate row y=1 by 22
rotate column x=22 by 5
rotate column x=1 by 4
rotate row y=4 by 5
rotate column x=6 by 2
rect 2x1
rotate row y=1 by 16
rotate column x=16 by 5
rotate column x=1 by 4
rotate row y=4 by 2
rotate column x=3 by 2
rect 2x1
rotate row y=1 by 3
rotate column x=3 by 5
rotate column x=1 by 4
rotate row y=4 by 2
rotate column x=3 by 2
rect 1x1
rotate row y=0 by 43
rotate column x=43 by 5
rect 1x1
rotate row y=0 by 32
rotate column x=32 by 5
rect 1x1
rotate row y=0 by 27
rotate column x=27 by 5
rect 1x1
rotate row y=0 by 7
rotate column x=7 by 5
rect 1x1
rotate row y=0 by 6
rotate column x=6 by 5
rect 1x1
rotate row y=0 by 2
rotate column x=2 by 5
rect 1x1
rotate row y=0 by 23
rotate column x=23 by 4
rect 1x1
rotate row y=0 by 47
rotate column x=47 by 3
rect 1x1
rotate row y=0 by 22
rotate column x=22 by 3
rect 1x1
rotate row y=0 by 42
rotate column x=42 by 1
rect 1x1
rotate row y=0 by 42
rotate column x=42 by 2
rect 1x1
rotate row y=0 by 28
rotate column x=28 by 2
rect 1x1
rotate row y=0 by 42
rotate column x=42 by 1
rect 1x1
rotate row y=0 by 25
rotate column x=25 by 1
rect 1x1
rotate row y=0 by 23
rotate column x=23 by 1
rect 1x1
rotate row y=0 by 20
rotate column x=20 by 1
rect 1x1
rotate row y=0 by 20
rotate column x=20 by 1
rect 1x1
rotate row y=0 by 20
rotate column x=20 by 1
rect 1x1
rotate row y=0 by 20
rotate column x=20 by 1
rect 1x1
rotate row y=0 by 13
rotate column x=13 by 1
rect 1x1
rotate row y=0 by 13
rotate column x=13 by 1
rect 1x1
rotate row y=0 by 13
rotate column x=13 by 1
rect 1x1
rotate row y=0 by 13
rotate column x=13 by 1
rect 1x1
rotate row y=0 by 10
rotate column x=10 by 1
rect 1x1
rotate row y=0 by 10
rotate column x=10 by 1
rect 1x1
rotate row y=0 by 10
rotate column x=10 by 1
rect 1x1
rotate row y=0 by 10
rotate column x=10 by 1
rect 1x1
rotate row y=0 by 8
rotate column x=8 by 1
rect 1x1
rotate row y=0 by 8
rotate column x=8 by 1
rect 1x1
rotate row y=0 by 8
rotate column x=8 by 1
rect 1x1
rotate row y=0 by 8
rotate column x=8 by 1
rect 1x1
rotate row y=0 by 5
rotate column x=5 by 1
rect 1x1
rotate row y=0 by 5
rotate column x=5 by 1
rect 1x1
rotate row y=0 by 5
rotate column x=5 by 1
rect 1x1
rotate row y=0 by 5
rotate column x=5 by 1
rect 1x1
rotate row y=0 by 1
rect 1x1
rotate row y=0 by 1
rect 1x1
rotate row y=0 by 2
rect 1x1
rotate row y=0 by 9
rect 1x1
rotate row y=0 by 4
rect 1x1
rotate row y=0 by 8
rect 1x1
rotate row y=0 by 1
rect 1x1
rotate row y=0 by 8
rect 1x1
rotate row y=0 by 3
rect 1x1
rotate row y=0 by 3
rect 1x1
rotate row y=0 by 1
rect 1x1
rotate row y=0 by 6
rect 1x1
rotate column x=0 by 1

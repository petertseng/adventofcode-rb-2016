require 'digest'

INPUT = (!ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read.chomp).freeze

MAZE_SIZE = 4
PADDED_SIZE = MAZE_SIZE + 2

# For bounds-checking, just create a border around the maze, and start at 1, 1.
in_bounds1 = (1..MAZE_SIZE)
IN_BOUNDS = Array.new(PADDED_SIZE ** 2) { |i|
  y, x = i.divmod(PADDED_SIZE)
  in_bounds1.cover?(y) && in_bounds1.cover?(x)
}

GOAL = MAZE_SIZE * PADDED_SIZE + MAZE_SIZE

MOVES = [
  [?U, -PADDED_SIZE],
  [?D, PADDED_SIZE],
  [?L, -1],
  [?R, 1],
].each { |m| m.each(&:freeze).freeze }.freeze

def doors(path)
  md5 = Digest::MD5.hexdigest(INPUT + path)
  MOVES.select.with_index { |_, i| 'bcdef'.include?(md5[i]) }
end

queue = [[PADDED_SIZE + 1, '']]
last_path = nil

# This could use Search.bfs and get a correct answer, but Search.bfs does too much bookkeeping.
# This is already a slow problem, so I don't want to make it any slower.
queue = queue.flat_map { |pos, path|
  if pos == GOAL
    puts path if last_path.nil?
    last_path = path
    next []
  end

  doors(path).filter_map { |(door, move)|
    [pos + move, path + door] if IN_BOUNDS[pos + move]
  }
} until queue.empty?

puts last_path.size

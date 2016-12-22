require_relative 'lib/search'

SHOW_MAP = ARGV.delete('-m')

Node = Struct.new(:x, :y, :size, :used, :avail, :use_pct)

nodes = ARGF.drop_while { |x| !x.start_with?(?/) }.map { |l|
  node = l.chomp.scan(/\d+/).map(&method(:Integer))
  raise "Not a df line: #{l}" unless node.size == 6
  Node.new(*node).freeze
}.freeze

HEIGHT = nodes.map(&:y).max + 1
WIDTH = nodes.map(&:x).max + 1

# We could exploit the fact that the nodes come in order,
# but let's be safe.
GRID = Array.new(HEIGHT) { Array.new(WIDTH) }
nodes.each { |n| GRID[n.y][n.x] = n }
GRID.each(&:freeze).freeze

# To check fewer pairs, sort first.
nodes_by_used = nodes.sort_by(&:used)
nodes_by_avail = nodes.sort_by(&:avail)

viable_pairs = 0
nonempty_pairs = false

nodes_by_used.each { |a|
  next if a.used == 0
  nodes_by_avail = nodes_by_avail.drop_while { |b| a.used > b.avail }
  break if nodes_by_avail.empty?
  nodes_by_avail.each { |b|
    if a != b && b.used > 0
      puts "#{a} and #{b} are a non-empty pair"
      nonempty_pairs = true
    end
  }
  viable_pairs += (nodes_by_avail - [a]).size
}

puts viable_pairs

# We're raising here simply because it will break the below algorithm.
# If any input has a pair with non-empty recipient, we should use it.
# But the below code can't smartly decide which pairs to use
# (in case one recipient could take from multiple senders)
raise 'non-empty pairs found, code needs to take them into account' if nonempty_pairs

empties = nodes.select { |n| n.used == 0 }

def assert_no_walls(nodes)
  largest = nodes.max_by(&:used)
  too_small = nodes.select { |n| n.size < largest.used }
  return if too_small.empty?
  puts too_small
  raise "#{too_small.size} nodes can't take data of #{largest}"
end

# For the below math to work, there must be no walls in the top two rows.
assert_no_walls(GRID[0..1].flatten)

# Note that compressing points didn't appear to make a difference.

puts empties.map { |empty|
  # Naively move the empty spot to y=0. What x does it end up at?
  (_, x), steps = Search.bfs(
    [empty.y, empty.x],
    neighbours: ->((y, x)) {
      my_size = GRID[y][x].size
      [
        ([y - 1, x] if y > 0),
        ([y + 1, x] if y + 1 < HEIGHT),
        ([y, x - 1] if x > 0),
        ([y, x + 1] if x + 1 < WIDTH),
      ].compact.select { |ny, nx|
        GRID[ny][nx].used <= my_size
      }
    },
    goal: ->((y, _)) { y == 0 },
  )[:goals].first
  # Move to (WIDTH - 2, 0), one to the left of the goal.
  steps += WIDTH - 2 - x
  # 1 step moves the goal data into (WIDTH - 2, 0), with empty space behind.
  steps += 1
  # 4 steps each to move the empty space from behind to in front,
  # 1 step to move the goal data
  steps + 5 * (WIDTH - 2)
}.min

puts GRID.map { |row|
  row.map { |node|
    wall = empties.none? { |e| node.used <= e.size }
    wall ? ?# : node.used == 0 ? ?_ : ?.
  }.join
} if SHOW_MAP

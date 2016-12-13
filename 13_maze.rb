require_relative 'lib/search'

def has_flag?(flag)
  ARGV.any? { |a| a.start_with?(?-) && a.include?(flag) }
end

INPUT = Integer(ARGV.find { |x| !x.start_with?(?-) } || ARGF.read)

def ones(n)
  ones = 0
  while n > 0
    n &= n - 1
    ones += 1
  end
  ones
end

def wall?(x, y)
  ones(x * x + 3 * x + 2 * x * y + y + y * y + INPUT) % 2 == 1
end

def adjacents((x, y))
  [
    [x - 1, y],
    [x + 1, y],
    [x, y - 1],
    [x, y + 1],
  ].select { |nx, ny| nx >= 0 && ny >= 0 && !wall?(nx, ny) }.map(&:freeze)
end

GOAL = if (garg = ARGV.find { |a| a.start_with?('-g') })
  ARGV.delete(garg)
  garg[2..-1].split(?,, 2).map(&method(:Integer))
else
  [31, 39]
end.freeze

results = Search.bfs(
  [1, 1],
  neighbours: ->pos { adjacents(pos) },
  goal: ->pos { pos == GOAL },
)

goal_dist = results[:goals][GOAL]
puts goal_dist

dists = if goal_dist > 50
  # We can use the existing search.
  results[:dist]
else
  # We have to do another search.
  # Search.bfs doesn't have a "count nodes at distance or less",
  # but we can upper-bound it by the number of reachable tiles without walls.
  # (1..50).sum to the lower-right:
  # 50 tiles if we go down all the way, 49 if we go right 1 down 49, etc.
  # 49 to the lower-left
  # 49 to the upper-right
  # 1 to the upper-left
  Search.bfs(
    [1, 1],
    num_goals: (1..50).sum + 49 + 49 + 1,
    neighbours: ->pos { adjacents(pos) },
    goal: ->_ { true },
  )[:dist]
end

puts dists.values.count { |steps| steps <= 50 }

(0..50).each { |y|
  puts (0..50).map { |x|
    wall?(x, y) ? ?# : dist[[x, y]] && dist[[x, y]] <= 50 ? ?O : ' '
  }.join
} if has_flag?(?f)

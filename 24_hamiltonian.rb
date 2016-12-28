require_relative 'lib/hamiltonian'
require_relative 'lib/search'

goals = []
start_pos = nil
width = nil

OPEN = ARGF.flat_map.with_index { |l, y|
  l.chomp!
  raise "inconsistent width #{width} vs #{l.size}" if width &.!= l.size
  width = l.size
  l.chars.map.with_index { |c, x|
    if c == ?0
      raise "Can't start at both #{start_pos} and #{y}, #{x}" if start_pos
      start_pos = y * width + x
    elsif c.match?(/\d/)
      goals << y * width + x
    end
    c != ?#
  }.freeze
}.freeze

raise 'no start pos' unless start_pos

dists = Hash.new { |h, k| h[k] = {} }

goal_or_start = ([start_pos] + goals).to_h { |gs| [gs, true] }.freeze
([start_pos] + goals).each { |src|
  Search.bfs(src, num_goals: goals.size, goal: goal_or_start.merge(src => false), neighbours: ->pos {
    [
      pos - width,
      pos + width,
      pos - 1,
      pos + 1,
    ].select { |npos| OPEN[npos] }
  })[:goals].each { |dest, dist| dists[src][dest] = dist }
}

# To turn a "best path starting from this node" problem
# into a "best cycle" problem,
# add a dummy node with costs:
# * zero to the start node + from any other node (or vice versa)
# * infinite anywhere else
dists[:dummy][start_pos] = 0
dists[start_pos][:dummy] = 1.0 / 0.0
goals.each { |g|
  dists[g][:dummy] = 0
  dists[:dummy][g] = 1.0 / 0.0
}

2.times {
  puts Graph.new(*Graph::from_hash(dists)).best[:min][:cost]
  dists.delete(:dummy)
}

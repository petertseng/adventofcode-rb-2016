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

puts goals.permutation.map { |order| [
  d = ([start_pos] + order).each_cons(2).sum { |a, b| dists[a][b] },
  d + dists[order.last][start_pos],
]}.transpose.map(&:min)
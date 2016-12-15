discs = ARGF.map { |l|
  id, positions, _, initial = l.scan(/\d+/).map(&method(:Integer))
  [id, positions, initial].freeze
}
discs << [discs.size + 1, 11, 0].freeze
discs.freeze

step = 1
t = 0
times = discs.map { |id, positions, initial|
  t += step until (id + t + initial) % positions == 0
  step = step.lcm(positions)
  t
}

puts times.last(2)

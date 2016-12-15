base_discs = ARGF.map { |l|
  id, positions, _, initial = l.scan(/\d+/).map(&method(:Integer))
  [id, positions, initial].freeze
}.freeze

[[], [[base_discs.size + 1, 11, 0].freeze]].each { |more_discs|
  discs = base_discs + more_discs
  puts 0.step.find { |t|
    discs.all? { |id, positions, initial|
      (id + t + initial) % positions == 0
    }
  }
}

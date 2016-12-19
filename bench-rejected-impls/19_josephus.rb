require 'benchmark'

N = Integer(!ARGV.empty? && ARGV.first.match?(/^\d+$/) ? ARGV.first : ARGF.read)

bench_candidates = [[], []]

bench_candidates[0] << def mod_adj(num_elves)
  (2..num_elves).reduce(0) { |winner, nn| (winner + 2) % nn } + 1
end

bench_candidates[0] << def queue_adj(num_elves)
  (num_elves - 1).times.with_object((1..num_elves).to_a) { |_, queue|
    queue << queue.shift(2).first
  }[0]
end

bench_candidates[0] << def array_adj(num_elves)
  right = Array.new(num_elves + 1) { |i| i + 1 }
  right[-1] = 1
  (1...num_elves).reduce(1) { |current, _|
    right[current] = right[right[current]]
  }
end

bench_candidates[1] << def mod_across(num_elves)
  (2..num_elves).reduce(0) { |winner, nn|
    # Insert a new elf before 0@n-1 in turn order.
    # If this new elf becomes 0@n,
    # the victim's @n-1 number will be (nn - 1 + (nn / 2)) % nn = nn / 2 - 1
    n_minus_1_would_kill = nn / 2 - 1
    # We need to maintain the same number of turns between 0@n and the winner.
    # This is so that the winner W@n-1 will still move at position W
    # after the first elimination brings n elves to n-1.
    # So, if the new elf would kill an elf between itself and the winner,
    # we have to let n-2@n-1 be 0@n instead. 0@n-1 would be 2@n, etc.
    # Otherwise, the new elf can be 0@n, and 0@n-1 can be 1@n, etc.
    (winner + (n_minus_1_would_kill > winner ? 1 : 2)) % nn
  } + 1
end

bench_candidates[1] << def pair_queue_across(num_elves)
  mid = num_elves / 2

  (num_elves - 1).times.with_object([
    (1..mid).to_a, ((mid + 1)..num_elves).to_a
  ]) { |i, (left, right)|
    right << left.shift
    right.shift
    left << right.shift if (num_elves - i).odd?
  }.flatten[0]
end

bench_candidates[1] << def one_queue_across(num_elves)
  elves = (1..num_elves).to_a
  until elves.size == 1
    eliminated = 0
    n = elves.size
    third = (n + 2) / 3
    third.times { |i|
      elves[i + eliminated + n / 2] = nil
      n -= 1
      eliminated += 1
    }
    elves = elves[third..-1].compact + elves[0...third]
  end
  elves[0]
end

bench_candidates[1] << def array_across(num_elves)
  right = Array.new(num_elves + 1) { |i| i + 1 }
  right[-1] = 1
  current = 1
  before_victim = num_elves / 2
  (num_elves - 1).downto(1) { |new_num_elves|
    after_victim = right[before_victim] = right[right[before_victim]]
    current = right[current]
    before_victim = after_victim if new_num_elves.even?
  }
  current
end

bench_candidates.each { |bcs|
  results = {}

  Benchmark.bmbm { |bm|
    bcs.each { |f|
      bm.report(f) { results[f] = send(f, N) }
    }
  }

  # Obviously the benchmark would be useless if they got different answers.
  if results.values.uniq.size != 1
    results.each { |k, v| puts "#{k} #{v}" }
    raise 'differing answers'
  end
}

N = Integer(!ARGV.empty? && ARGV.first.match?(/^\d+$/) ? ARGV.first : ARGF.read)

# the zero-based index of the survivor
def survivor_fixed(n, k)
  (2..n).reduce(0) { |winner, nn| (winner + k) % nn }
end

# the zero-based index of the survivor
def survivor_variable(n)
  (2..n).reduce(0) { |winner, nn|
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
  }
end

puts survivor_fixed(N, 2) + 1
puts survivor_variable(N) + 1

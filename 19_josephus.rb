N = Integer(!ARGV.empty? && ARGV.first.match?(/^\d+$/) ? ARGV.first : ARGF.read)

# At n = 1, elf 1 (one-indexed) wins.
# At n = 2^k, after n/2 turns half the elves are left,
#   and it's elf 1's turn again.
# So at all powers of 2, elf 1 wins.
# Otherwise, write n as 2^k + r.
# After r turns, the next mover (2r + 1) wins.
# So, take out the MSB, shift left by 1, add 1.
puts Integer(N.to_s(2)[1..-1] + ?1, 2)

# At n = 1, elf 1 (one-indexed) wins.
# Eliminated elves start at one-indexed m = (n / 2) + 1
# and alternate increasing by 1 and 2.
# Start with 1 if n even, 2 if n odd.
# That means first survivor is m + 2 if n even, or m + 1 if n odd.
# At n = 3^k, after 2n/3 turns a third of the elves are left,
# corresponding to every third elf of the n.
# This means the elf that just acted will go last and win.
# (elf 1 is not special here, since elf 1 might die).
# So at all powers of 3, elf n wins.
# Otherwise, write n as 3^k + r.
# After r turns, the previous mover wins.
# As long as that's less than m, that's r.
# Otherwise, that's first_survivor + 3 * (r - m)
#
# Alternative formulation:
# if MST is 1, remove the 1.
# if MST is 2, change it to 1, double the value of all other trits.
def survivor_variable(n)
  trits = n.to_s(3)
  power_of_three = 3 ** (trits.size - 1)
  return n if n == power_of_three
  r = n - power_of_three
  first_kill = n / 2 + 1
  first_survivor = first_kill + 2 - n % 2
  r < first_kill ? r : first_survivor + 3 * (r - first_kill)
end

puts survivor_variable(N)

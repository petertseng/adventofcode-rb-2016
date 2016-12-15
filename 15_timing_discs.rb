# returns [gcd, x]
# a * x + n * y == gcd
# Doesn't return y, because I don't need it.
#
# the inverse of a modulo n would be:
# gcd > 1 ? nil : x % n
def egcd(a, n)
  t, newt = [0, 1]
  r, newr = [n, a]
  until newr == 0
    q = r / newr
    t, newt = [newt, t - q * newt]
    r, newr = [newr, r - q * newr]
  end
  [r, t]
end

discs = ARGF.map { |l|
  id, positions, _, initial = l.scan(/\d+/).map(&method(:Integer))
  [id, positions, initial].freeze
}
discs << [discs.size + 1, 11, 0].freeze
discs.freeze

step = 1
t = 0
times = discs.map { |id, positions, initial|
  # See 2020 day 13 for explanation of this.
  gcd, x = egcd(step, positions)
  initial_diff = -(id + initial + t)
  raise "can't #{step} #{positions} because offset #{initial_diff} vs gcd #{gcd}" if initial_diff % gcd != 0
  t += step * (((initial_diff % positions) * x) % positions) / gcd
  step = step.lcm(positions)
  t
}

puts times.last(2)

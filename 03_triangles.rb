input = ARGF.map { |l| l.split.map(&method(:Integer)).freeze }.freeze

def tri?(a, b, c)
  a + b > c
end

puts input.count { |x| tri?(*x.sort) }
puts input.each_slice(3).sum { |rows|
  rows.transpose.count { |x| tri?(*x.sort) }
}

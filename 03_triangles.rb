input = ARGF.map { |l| l.split.map(&method(:Integer)).freeze }.freeze

def tri?(a, b, c)
  a + b > c
end

puts input.count { |x| tri?(*x.sort) }
puts input.each_slice(3).sum { |rows|
  [0, 1, 2].count { |col|
    tri?(*rows.map { |r| r[col] }.sort)
  }
}

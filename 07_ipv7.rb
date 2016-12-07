ABBA = /(.)(?!\1)(.)\2\1/
HYPERNET = /\[[^\]]+\]/

addrs = ARGF.map { |addr| [
  addr.scan(HYPERNET),
  addr.gsub(HYPERNET, '[!]'),
].freeze }.freeze

puts addrs.count { |hypernets, supernets|
  supernets.match?(ABBA) && hypernets.none?(ABBA)
}

puts addrs.count { |hypernets, supernets|
  hypernets.flat_map { |hypernet|
    hypernet.each_char.each_cons(3).select { |a, b, c|
      a == c && a != b
    }
  }.any? { |b, a, _| supernets.include?(a + b + a) }
}

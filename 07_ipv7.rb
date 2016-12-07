ABBA = /(.)(?!\1)(.)\2\1/
# positive lookahead lets scan find overlaps.
# Important note of String#scan:
# If the pattern contains no groups,
# each individual result consists of the matched string, $&.
# That means the entire regex must be a lookahead,
# rather than, say, /(.)(?=(?!\1).\1)/
ABA = /(?=((.)(?!\2).\2))/
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
    hypernet.scan(ABA).map { |m| m.first.chars }
  }.any? { |b, a, _| supernets.include?(a + b + a) }
}

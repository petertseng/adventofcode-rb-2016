module IPv7; refine String do
  def has_abba?
    scan(/(.)(.)\2\1/).any? { |abba| abba[0] != abba[1] }
  end
end end

using IPv7

HYPERNET = /\[[^\]]+\]/

addrs = ARGF.map { |addr| [
  addr.scan(HYPERNET),
  addr.gsub(HYPERNET, '[!]'),
].freeze }.freeze

puts addrs.count { |hypernets, supernets|
  supernets.has_abba? && hypernets.none? { |hn| hn.has_abba? }
}

puts addrs.count { |hypernets, supernets|
  hypernets.flat_map { |hypernet|
    hypernet.each_char.each_cons(3).select { |a, b, c|
      a == c && a != b
    }
  }.any? { |b, a, _| supernets.include?(a + b + a) }
}

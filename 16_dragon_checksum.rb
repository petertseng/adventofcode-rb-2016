lengths = if (larg = ARGV.find { |a| a.start_with?('-l') })
  ARGV.delete(larg)
  larg[2..-1].split(?,).map(&method(:Integer))
else
  [272, 35651584]
end.freeze

input = (!ARGV.empty? && (v = ARGV.find { |arg| arg.match?(/^[01]+$/)}) ? v : ARGF.read).freeze
bit = {?1 => true, ?0 => false}.freeze
orig_a = input.each_char.map { |c| bit.fetch(c) }.freeze

lengths.each { |disk|
  a = orig_a.dup
  a += [false] + a.reverse.map { |x| !x } until a.size >= disk
  sum = a.take(disk)
  sum = sum.each_slice(2).map { |x, y| x == y } until sum.size % 2 == 1
  puts sum.map { |x| x ? ?1 : ?0 }.join
}

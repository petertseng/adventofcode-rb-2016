test = ARGV.delete('-t')

input = !ARGV.empty? && ARGV.first.match?(/^[01]+$/) ? ARGV.first : ARGF.read

(test ? [20] : [272, 35651584]).each { |disk|
  a = input.each_char.map { |c| c == ?1 }
  a += [false] + a.reverse.map { |x| !x } until a.size >= disk
  sum = a.take(disk)
  sum = sum.each_slice(2).map { |x, y| x == y } until sum.size % 2 == 1
  puts sum.map { |x| x ? ?1 : ?0 }.join
}

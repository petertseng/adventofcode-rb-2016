ROOM = %r{^(?<name>[-a-z]+)(?<sector>\d+)\[(?<sum>[a-z]{5})\]$}

real = ARGF.map(&ROOM.method(:match)).select { |i|
  freq = i[:name].each_char.tally
  freq.delete(?-)
  freq.sort_by { |a, b| [-b, a] }.map(&:first).take(5).join == i[:sum]
}

puts real.sum { |i| Integer(i[:sector]) }

alpha = 'abcdefghijklmnopqrstuvwxyz'.freeze

names = real.map { |r|
  shift = Integer(r[:sector]) % 26
  r[:name].tr(alpha, alpha.chars.rotate(shift).join) + r[:sector]
}

puts names.grep(/north/)

require_relative 'lib/assembunny'
assembler = Assembunny::Interpreter.new(ARGF.readlines)

[7, 12].each { |a|
  puts assembler.run({a: a, b: 0, c: 0, d: 0})[:a]
}

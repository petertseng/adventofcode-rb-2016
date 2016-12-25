require_relative 'lib/assembunny'
assembler = Assembunny::Interpreter.new(ARGF.readlines)

[0, 1].each { |c|
  puts assembler.run({a: 0, b: 0, c: c, d: 0})[0][:a]
}

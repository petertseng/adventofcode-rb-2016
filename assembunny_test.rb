require_relative 'lib/assembunny'

assembler = Assembunny::Interpreter.new(<<MUL.lines)
cpy b c
inc a
dec c
jnz c -2
dec d
jnz d -5
MUL

puts assembler.run({a: 0, b: 13, c: 0, d: 11}, debug: true, opt: false)
puts assembler.run({a: 0, b: 13, c: 0, d: 11}, debug: true)

(0..500).each{ |t|
  regs1 = assembler.run({a: 0, b: 13, c: 0, d: 11}, max_vt: t)
  regs2 = assembler.run({a: 0, b: 13, c: 0, d: 11}, max_vt: t, opt: false)
  raise "at t = #{t}: with opt #{regs1}, without opt #{regs2}" if regs1 != regs2
}

assembler = Assembunny::Interpreter.new(<<DIV.lines)
cpy d c
jnz b 2
jnz 1 6
dec b
dec c
jnz c -4
inc a
jnz 1 -7
DIV

puts assembler.run({a: 0, b: 17, c: 0, d: 2}, debug: true, opt: false)
puts assembler.run({a: 0, b: 17, c: 0, d: 2}, debug: true)

(2..4).each { |div|
  (0..200).each { |t|
    (17...(17 + div)).each { |n|
      regs1 = assembler.run({a: 0, b: n, c: 0, d: div}, max_vt: t)
      regs2 = assembler.run({a: 0, b: n, c: 0, d: div}, max_vt: t, opt: false)
      raise "at t = #{t} #{n} / #{div}: with opt #{regs1}, without opt #{regs2}" if regs1 != regs2
    }
  }
}

# pre-parse the input so we don't have to do as much work in the loop.
input = ARGF.readlines.map(&:split).map { |words|
  args = words[1..-1].map { |x| x.match?(/\d+/) ? Integer(x) : x.to_sym }
  if words[0] == 'cpy'
    [args[0].is_a?(Integer) ? :load : :copy, args[1], args[0]]
  else
    [words[0].to_sym] + args
  end
}.map(&:freeze).freeze

def run(input, regs)
  pc = -1
  while (inst = input[pc += 1])
    case inst[0]
    when :load; regs[inst[1]] = inst[2]
    when :copy; regs[inst[1]] = regs[inst[2]]
    when :inc; regs[inst[1]] += 1
    when :dec; regs[inst[1]] -= 1
    # -1 to offset the standard increment
    when :jnz; pc += inst[2] - 1 if regs[inst[1]] != 0
    else raise "Unknown instruction #{inst}"
    end
  end
  regs
end

regs = {a: 0, b: 0, c: 0, d: 0}
[{}, {c: 1}].each { |h| puts run(input, regs.merge(h))[:a] }

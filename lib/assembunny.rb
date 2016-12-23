module Assembunny class Interpreter
  def initialize(lines)
    @original = lines.map(&:split).map { |words|
      args = words[1..-1].map { |x| x.match?(/\d+/) ? Integer(x) : x.to_sym }
      if words[0] == 'cpy'
        [args[0].is_a?(Integer) ? :load : :copy, args[1], args[0]]
      else
        [words[0].to_sym] + args
      end
    }.map(&:freeze)
  end

  def optimise(original)
    opt = original.dup

    # x += y
    opt.each_cons(3).with_index { |(inc, dec, jnz), i|
      # inc a
      # dec d
      # jnz d -2
      next unless inc[0] == :inc && dec[0] == :dec && jnz == [:jnz, dec[1], -2]
      # inc_by a d
      opt[i] = [:inc_by, inc[1], dec[1]].freeze
    }

    opt.freeze
  end

  def run(regs)
    optimised = optimise(@original)

    pc = -1
    while (inst = optimised[pc += 1])
      case inst[0]
      when :load; regs[inst[1]] = inst[2]
      when :copy; regs[inst[1]] = regs[inst[2]]
      when :inc; regs[inst[1]] += 1
      when :dec; regs[inst[1]] -= 1
      # -1 to offset the standard increment
      when :jnz; pc += inst[2] - 1 if regs[inst[1]] != 0
      when :inc_by
        regs[inst[1]] += regs[inst[2]]
        regs[inst[2]] = 0
        pc += 2
      else raise "Unknown instruction #{inst}"
      end
    end
    regs
  end
end end

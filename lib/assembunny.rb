module Assembunny class Interpreter
  def initialize(lines)
    @original = lines.map(&:split).map { |words|
      [words[0].to_sym] + words[1..-1].map { |x|
        x.match?(/\d+/) ? Integer(x) : x.to_sym
      }
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

    val = ->(n) { n.is_a?(Integer) ? n : regs.fetch(n) }

    pc = -1
    while pc >= -1 && (inst = optimised[pc += 1])
      case inst[0]
      when :cpy; regs[inst[2]] = val[inst[1]]
      when :inc; regs[inst[1]] += 1
      when :dec; regs[inst[1]] -= 1
      # -1 to offset the standard increment
      when :jnz; pc += val[inst[2]] - 1 if val[inst[1]] != 0
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

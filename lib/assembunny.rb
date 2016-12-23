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

    # x += y * z
    opt.each_cons(6).with_index { |(cpy, incby, _, _, dec, jnz), i|
      # cpy b c
      # inc a    \
      # dec c     > inc_by a c
      # jnz c -2 /
      # dec d
      # jnz d -5
      next unless cpy[0] == :cpy && incby[0] == :inc_by && cpy[2] == incby[2]
      next unless dec[0] == :dec && jnz == [:jnz, dec[1], -5]
      # inc_by_mul a d b c (b might be reg or imm)
      opt[i] = [:inc_by_mul, incby[1], dec[1], cpy[1], incby[2]].freeze
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
      when :inc_by_mul
        regs[inst[1]] += regs[inst[2]] * val[inst[3]]
        regs[inst[2]] = 0
        regs[inst[4]] = 0
        pc += 5
      else raise "Unknown instruction #{inst}"
      end
    end
    regs
  end
end end

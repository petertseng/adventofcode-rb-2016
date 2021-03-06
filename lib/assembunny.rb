module Assembunny class Interpreter
  def initialize(lines)
    @original = lines.map(&:split).map { |words|
      [words[0].to_sym] + words[1..-1].map { |x|
        x.match?(/\d+/) ? Integer(x) : x.to_sym
      }
    }.map(&:freeze)
  end

  def effective(inst_and_toggle)
    inst_and_toggle.map { |(cmd, *args), toggle|
      new_cmd = cmd
      if toggle
        case args.size
        when 2; new_cmd = (cmd == :jnz ? :cpy : :jnz)
        when 1; new_cmd = (cmd == :inc ? :dec : :inc)
        else raise "Unsupported argument size: #{cmd} #{args}"
        end
      end
      [new_cmd, *args].freeze
    }.freeze
  end

  def optimise(original)
    opt = original.dup

    # x += y
    opt.each_cons(3).with_index { |(inc, dec, jnz), i|
      # inc a
      # dec d
      # jnz d -2
      next unless inc[0] == :inc && dec[0] == :dec && jnz == [:jnz, dec[1], -2]
      next unless [inc[1], dec[1]].all? { |x| x.is_a?(Symbol) }
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
      next unless [dec[1], *incby[1..2]].all? { |x| x.is_a?(Symbol) }
      # inc_by_mul a d b c (b might be reg or imm)
      opt[i] = [:inc_by_mul, incby[1], dec[1], cpy[1], incby[2]].freeze
    }

    # q, r = x / d, d - (x % d)
    opt.each_cons(8).with_index { |(cpydr, jnzx, jmp1, decx, decr, jnzr, incq, jmp2), i|
      # cpy 2 c
      # jnz b 2
      # jnz 1 6
      # dec b
      # dec c
      # jnz c -4
      # inc a
      # jnz 1 -7
      next unless jmp1 == [:jnz, 1, 6] && jmp2 == [:jnz, 1, -7]
      next unless jnzx == [:jnz, decx[1], 2] && jnzr == [:jnz, decr[1], -4]
      next unless [decx, decr].all? { |inst| inst[0] == :dec }
      next unless cpydr[0] == :cpy && cpydr[2] == decr[1]
      next unless incq[0] == :inc
      next unless [decx, decr, incq].all? { |x| x[1].is_a?(Symbol) }
      # divmod x d q r (d might be reg or imm)
      opt[i] = [:divmod, decx[1], cpydr[1], incq[1], decr[1]].freeze
    }

    opt.freeze
  end

  def run(regs, outs: [], debug: false, max_vt: 1.0 / 0.0, opt: true)
    store_outs = outs == :store
    outs = [] if store_outs
    toggles = @original.map { false }
    optimised = opt ? optimise(@original) : @original

    val = ->(n) { n.is_a?(Integer) ? n : regs.fetch(n) }

    pc = -1

    good_outs = 0

    debuginfo = {}
    t = 0
    vt = 0
    add_debug = ->{
      reg_str = regs.to_h { |k, v| [k, "#{k}: #{v}".freeze] }.freeze
      inst_str = optimised.map { |o| o.join(' ').freeze }.freeze
      debuginfo[t] = {
        vt: vt,
        regs: regs.dup,
        pc: pc,
        reg_str: reg_str,
        inst: optimised.dup,
        inst_str: inst_str,
        width: (reg_str.values + inst_str).map(&:size).max,
      }
    }
    add_debug[]

    while vt <= max_vt && pc >= -1 && (inst = optimised[pc += 1])
      t += 1
      vt += 1
      case inst[0]
      when :cpy; regs[inst[2]] = val[inst[1]] if inst[2].is_a?(Symbol)
      when :inc; regs[inst[1]] += 1 if inst[1].is_a?(Symbol)
      when :dec; regs[inst[1]] -= 1 if inst[1].is_a?(Symbol)
      # -1 to offset the standard increment
      when :jnz; pc += val[inst[2]] - 1 if val[inst[1]] != 0
      when :inc_by
        vt += regs[inst[2]] * 3 - 1
        regs[inst[1]] += regs[inst[2]]
        regs[inst[2]] = 0
        pc += 2
      when :inc_by_mul
        vt += (1 + val[inst[3]] * 3 + 2) * regs[inst[2]] - 1
        regs[inst[1]] += regs[inst[2]] * val[inst[3]]
        regs[inst[2]] = 0
        regs[inst[4]] = 0
        pc += 5
      when :divmod
        div = val[inst[2]]
        quot, mod = regs[inst[1]].divmod(div)
        vt += 3 + quot * (7 + 4 * (div - 1)) + mod * 4 - 1
        regs[inst[1]] = 0
        regs[inst[3]] = quot
        regs[inst[4]] = div - mod
        pc += 7
      when :tgl
        target = pc + val[inst[1]]
        if 0 <= target && target < optimised.size
          toggles[target] ^= true
          e = effective(@original.zip(toggles))
          optimised = opt ? optimise(e) : e
          add_debug[]
        end
      when :out
        if store_outs
          outs << val[inst[1]]
        else
          break if val[inst[1]] != outs[good_outs]
          good_outs += 1
          break if good_outs == outs.size
        end
      else raise "Unknown instruction #{inst}"
      end
    end

    add_debug[]

    if debug
      inst_width = (optimised.size - 1).to_s.size
      puts (' ' * (inst_width + 1)) + debuginfo.map { |dt, dd|
        "t = #{dt}, pc = #{dd[:pc]}".ljust(dd[:width])
      }.join('|')
      puts (' ' * (inst_width + 1)) + debuginfo.map { |dt, dd|
        "vt = #{dd[:vt]}".ljust(dd[:width])
      }.join('|')
      regs.each_key { |reg|
        puts (' ' * (inst_width + 1)) + debuginfo.map { |_, dd|
          dd[:reg_str][reg].ljust(dd[:width])
        }.join('|')
      }
      max_inst = debuginfo.values.map { |d| d[:inst].size }.max
      max_inst.times { |n|
        prev = nil
        puts ("%#{inst_width}d " % n) + debuginfo.map { |_, dd|
          inst = dd[:inst_str][n]
          first = prev.nil?
          changed = prev && prev != inst
          prev = inst
          show_anyway = false
          "\e[#{changed ? 1 : 0}m#{(first || changed || show_anyway ? inst : '').ljust(dd[:width])}\e[0m"
        }.join('|')
      }
    end

    [regs, store_outs ? outs : good_outs]
  end
end end

require 'set'

face = 1
pos = Complex(0, 0)
locs = Set.new([pos])
first_repeat = nil

ARGF.read.split(?,) { |inst|
  inst.strip!
  face *= Complex(0, {?L => 1, ?R => -1}.fetch(inst[0]))
  steps = Integer(inst[1..-1])

  steps.times {
    pos += face
    unless first_repeat
      first_repeat = pos if locs.include?(pos)
      locs.add(pos)
    end
  }
}

[pos, first_repeat].each { |p| puts (p ? p.real.abs + p.imag.abs : 'no') }

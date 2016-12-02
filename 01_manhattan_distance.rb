require 'set'

face = 0
pos = [0, 0]
locs = Set.new([pos.dup])
first_repeat = nil

ARGF.read.split(?,) { |inst|
  inst.strip!
  face += {?L => -1, ?R => 1}.fetch(inst[0])
  face %= 4
  steps = Integer(inst[1..-1])

  # 0 north 1 east 2 south 3 west
  coord = face % 2
  dir = face / 2 == 0 ? 1 : -1

  steps.times {
    pos[coord] += dir
    unless first_repeat
      first_repeat = pos.dup if locs.include?(pos)
      locs.add(pos.dup)
    end
  }
}

[pos, first_repeat].each { |p| puts (p ? p.sum(&:abs) : 'no') }

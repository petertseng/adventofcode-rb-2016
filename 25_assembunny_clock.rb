require_relative 'lib/assembunny'
assembler = Assembunny::Interpreter.new(ARGF.readlines)

# We can't be sure that any number of bits is enough for *arbitrary* input,
# But for *my* input, the program outputs the binary of (a + 2532).
# We need a + 2532 to be a number in the recurrence:
# f(1) = 2, f(n) = 4 * f(n - 1) + 2.
#
# Enumerator.produce(2) { |v| 4 * v + 2 }.take(10)
# [2, 10, 42, 170, 682, 2730, 10922, 43690, 174762, 699050]
#
# If f(CYCLES) > 2532, we find the right answer before any false positive,
# The first false positive would be Integer("1" + "10" * CYCLES, 2) - 2532.
# CYCLES == 6 suffices for my input.
# Empirically, even CYCLES == 4 happens to get the right answer.
# We'll use 100 so that an input has to try hard to cause false positives.
CYCLES = 100
EXPECTED = ([0, 1] * CYCLES).freeze

0.step { |a|
  _, good_outs = assembler.run({a: a, b: 0, c: 0, d: 0}, outs: EXPECTED)
  (puts a; break) if good_outs == EXPECTED.size
}

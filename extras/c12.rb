require 'open3'
require 'tempfile'

def to_c(input, regs)
  prologue = [
    '#include <stdio.h>',
    'int main() {',
  ] + regs.map { |k, v|
    "  int #{k} = #{v};"
  }

  come_from = Hash.new { |h, k| h[k] = [] }

  body = input.map.with_index { |line, i|
    words = line.split
    case words[0]
    when 'cpy'; "#{words[2]} = #{words[1]};"
    when 'inc'; "++#{words[1]};"
    when 'dec'; "--#{words[1]};"
    when 'jnz'
      target = i + Integer(words[2])
      come_from[target] << i
      "if (#{words[1]} != 0) { goto line#{target}; } // line #{i}"
    end
  }.flat_map.with_index { |line, i| [
    ("line#{i}: // from #{come_from[i]}" if come_from.has_key?(i)),
    "  #{line}",
  ].compact }

  epilogue = [
    '  printf("%d\n", a);',
    '  return 0;',
    '}',
  ]

  prologue + body + epilogue
end

cval = begin
  arg = ARGV.find { |x| x.start_with?(?-) && x.include?(?c) }
  arg ? Integer(arg[(arg.index(?c) + 1)..-1]) : 0
end

verbose = ARGV.any? { |a| a.start_with?(?-) && a.include?(?v)  }
ARGV.reject! { |x| x.start_with?(?-) }
code = to_c(ARGF.readlines, {a: 0, b: 0, c: cval, d: 0})
puts code if verbose

OUTPUT = 'compiled'

File.delete(OUTPUT) if File.exist?(OUTPUT)

Open3.popen2('gcc', '-O2', '-xc', "-o#{OUTPUT}", ?-) { |stdin, stdout, _|
  stdin.puts(code)
}

system("./#{OUTPUT}")

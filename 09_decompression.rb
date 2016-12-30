def decompress(input, deep: false)
  length = 0
  i = 0

  while (c = input[i])
    if c == ?(
      close_paren = input.index(?), i + 1)
      chars, times = input[(i + 1)...close_paren].split(?x).map(&method(:Integer))
      if deep
        subseq = input[close_paren + 1, chars]
        length += decompress(subseq, deep: true) * times
      else
        length += chars * times
      end
      i = close_paren + chars + 1
    else
      next_paren = input.index(?(, i + 1) || input.size
      length += next_paren - i
      i = next_paren
    end
  end

  length
end

input = ARGF.read.strip.freeze
[false, true].each { |deep| puts decompress(input, deep: deep) }

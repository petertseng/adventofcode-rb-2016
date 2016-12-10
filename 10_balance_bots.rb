Bot = Struct.new(:id, :nums, :low_to, :high_to) {
  def <<(n)
    nums << n
    nums.sort!
    puts id if nums == [17, 61]
  end

  def ready?
    nums.size == 2
  end

  def run!
    [low_to, high_to].zip(nums.shift(2)).select { |to, num|
      to << num
      to.is_a?(Bot) && to.ready?
    }.map(&:first)
  end
}

bots = Hash.new { |h, k| h[k] = Bot.new(k, []) }
outputs = Hash.new { |h, k| h[k] = [] }

ARGF.each_line { |l|
  words = l.split

  parse_target = ->(at:) {
    case (type = words[at])
    when 'bot'; bots
    when 'output'; outputs
    else raise "what is a #{type}?"
    end[Integer(words[at + 1])]
  }

  case (cmd = words[0])
  when 'value'; bots[Integer(words[-1])] << Integer(words[1])
  when 'bot'
    bot = bots[Integer(words[1])]
    bot.low_to = parse_target[at: 5]
    bot.high_to = parse_target[at: -2]
  else raise "what is a #{cmd}?"
  end
}

ready_bots = bots.values.select(&:ready?)
ready_bots = ready_bots.flat_map(&:run!) until ready_bots.empty?

puts (0..2).map { |i| outputs[i].first }.reduce(:*)

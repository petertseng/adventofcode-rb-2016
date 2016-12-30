require "../lib/branch_and_bound"

dists = {} of Int32 => Hash(Int32, Distance)

File.read_lines(ARGV.first).each_with_index { |l, i|
  entries = l.split.map(&.to_i)
  dists[i] = entries.map_with_index { |e, j|
    {j, i == j ? 1.0 / 0.0 : e}
  }.to_h
}

t = Time.utc
puts BranchAndBound.best_cycle(dists)
puts Time.utc - t

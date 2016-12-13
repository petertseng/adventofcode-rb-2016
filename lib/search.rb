module Search
  module_function

  def bfs(start, num_goals: 1, neighbours:, goal:)
    current_gen = [start]
    dist = {start => 0}
    goals = {}
    gen = -1

    until current_gen.empty?
      gen += 1
      next_gen = []
      while (cand = current_gen.shift)
        if goal[cand]
          goals[cand] = gen
          if goals.size >= num_goals
            next_gen.clear
            break
          end
        end

        neighbours[cand].each { |neigh|
          next if dist.has_key?(neigh)
          dist[neigh] = gen + 1
          next_gen << neigh
        }
      end
      current_gen = next_gen
    end

    {
      gen: gen,
      goals: goals.freeze,
      dist: dist.freeze,
    }.freeze
  end
end

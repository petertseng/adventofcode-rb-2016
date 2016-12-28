module Bits
  BIT_POSITION = [
    0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
    31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9,
  ].freeze

  # Finds the index of the last-significant one bit.
  # (equivalently the number of trailing zeroes)
  def self.index_of_one(x)
    # Uses a multiply-and-lookup with a de Bruijn sequence.
    BIT_POSITION[(((x & -x) * 0x77CB531) >> 27) & 31]
  end

  # Returns the next-largest integer than x that has as many one bits as x.
  def self.next_combination(x)
    smallest = x & -x
    ripple = x + smallest
    new_smallest = ripple & -ripple
    ones = ((new_smallest / smallest) >> 1) - 1
    ripple | ones
  end

  # Yields the index and value of each bit that is set in x.
  def self.each_bit(x)
    while x > 0
      index = index_of_one(x)
      bit = 1 << index
      x &= ~bit
      yield index, bit
    end
  end

  # Yields each number of at most max_width bits that has size bits set.
  def self.each_bit_combination(size, max_width)
    set_bits = (1 << size) - 1
    limit = 1 << max_width
    while set_bits < limit
      yield set_bits
      set_bits = next_combination(set_bits)
    end
  end
end

class Graph
  def initialize(names, distances)
    @names = names.freeze
    # distances[x][y] needs to be distance TO x FROM y.
    # This is due to how it is used in #best.
    # If distances are symmetric, no problem. Otherwise, take heed.
    @distances = distances.freeze
    @distances.each(&:freeze)
  end

  def self.paths(hash)
    new(*from_hash(hash, dummy: true)).best(max: true).each_value { |v|
      v[:path].shift
    }
  end

  def self.maxes(hash)
    metrics = {min: false, max: true}
    path = new(*from_hash(hash, dummy: true)).best(**metrics)[:max]
    path[:path].shift
    {
      cycle: new(*from_hash(hash)).best(**metrics)[:max],
      path: path,
    }
  end

  def self.from_hash(distance_hash, dummy: false)
    names = distance_hash.keys
    distances = names.map.with_index { |name1, i|
      names.map.with_index { |name2, j|
        i == j ? 0 : distance_hash[name1][name2]
      }
    }

    if dummy
      names.unshift(nil)
      distances.each { |d| d.unshift(0) }
      distances.unshift(Array.new(names.size, 0))
    end

    [names, distances]
  end

  # This uses the Held-Karp algorithm to find the best cycle.
  def best(min: true, max: false)
    # best_cost and best_prev are both Array[Hash[Integer => Integer]].
    # The array index is a node index, and the hash key is a bitfield of nodes.
    # best_cost[x][s] and best_prev[x][s] respectively represent:
    # optimal cost   of a path starting at 0, visiting nodes in s, ending at x.
    # penultimate node in path starting at 0, visiting nodes in s, ending at x.
    best_cost = Array.new(@distances.size) { {} }
    best_prev = Array.new(@distances.size) { {} }

    # Without loss of generality, pick 0 to be the first node in the cycle.
    # This is WLOG because the best cycle is invariant to rotation.

    (1...@distances.size).each { |i|
      # when s.size == 0, that's easy, we just go from node 0 to node i.
      dist1 = @distances[i][0]
      best_cost[i][0] = dist1
      bit = 1 << i

      # when s.size == 1, that's also easy.
      # Go from node 0 to (the node in s) to node j
      # Do this for every combination of two nodes.
      (1...@distances.size).each { |j|
        next if i == j
        dist2 = @distances[j][i]
        best_cost[j][bit] = dist1 + dist2
        best_prev[j][bit] = i
      }
    }

    answers = {}
    answers[:min] = new_answer(best_cost, best_prev, Float::INFINITY, :<.to_proc) if min
    answers[:max] = new_answer(best_cost, best_prev, 0, :>.to_proc) if max

    (3...@distances.size).each { |size|
      # We're considering each combination of elements of this size,
      # excluding element 0 since it is visited first.
      # So we want (N - 1) choose size.
      Bits.each_bit_combination(size, @distances.size - 1) { |set_bits|
        # Since we exclude element 0, bit 0 is always 0.
        # The set_bits represent the other elements, so we need to shift.
        set_bits <<= 1
        # For each node k in this set s,
        Bits.each_bit(set_bits) { |index_k, bit_k|
          # Find the best way to start at node 0, visit all nodes in (s - {k}),
          # and then end at k.
          other_bits = set_bits & ~bit_k
          new_answers = sub_best(other_bits, answers, @distances[index_k])
          update_bests(answers, index_k, other_bits, new_answers)
        }
      }
    }

    # A number with @distances.size bits set, minus 1 to exclude element 0.
    # That's (1 << @distances.size) - 1 - 1.
    bits = (1 << @distances.size) - 2

    # The best cycle is the best way to start at node 0, visit all other nodes,
    # then end at node 0 again.
    answers.merge(sub_best(bits, answers, @distances[0])) { |_, ans, new_ans|
      path = reconstruct_path(ans[:prev], new_ans[:prev])
      {
        cost: new_ans[:cost],
        path: path.map { |i| @names[i] },
      }
    }
  end

  private

  # new_answers might look like:
  # {min: {cost: 50, prev: 1}, max: {cost: 200, prev: 2}}
  # answers looks like:
  # {min: {cost: Hash, prev: Hash}, max: cost: Hash, prev: Hash}
  #
  # update_bests inserts the values into the hashes at [index_k][other_bits]
  # answers[:min][:cost][index_k][other_bits] = new_answers[:min][:cost], etc.
  def update_bests(answers, index_k, other_bits, new_answers)
    answers.merge!(new_answers) { |_, ans, new_ans|
      ans.merge!(new_ans) { |_, hash, new_val|
        hash.tap { |h| h[index_k][other_bits] = new_val }
      }
    }
  end

  def new_answer(cost, prev, initial, accept)
    {
      cost: cost.map(&:dup),
      prev: prev.map(&:dup),
      initial: initial,
      current: nil,
      accept: accept,
    }
  end

  def reconstruct_path(best_prev, prev)
    path = [0, prev]
    bits = (1 << @distances.size) - 2
    (@distances.size - 2).times {
      bits &= ~(1 << prev)
      prev = best_prev[prev][bits]
      path << prev
    }
    path
  end

  # Given some node v and nodes represented in bitfield other_bits,
  # with distance to v from each node in distances (Array[Integer]),
  # and previous bests in bests (Hash[Symbol => Answer]),
  # returns Hash[Symbol => {cost: Integer, prev: Integer}]
  # representing, for each Answer type, the best way to construct a path
  # starting at node 0, visiting all nodes in other_bits, and ending at v.
  #
  # Answer must be a Hash containing at least the keys:
  # * :cost (best costs so far, see best_costs in #best for semantics)
  # * :initial (initial best value)
  # * :accept (two-arg proc: does first arg (new) beat second arg (old)?)
  def sub_best(other_bits, bests, distances)
    bests.each_value { |v|
      v[:current_cost] = v[:initial]
      v[:current_prev] = nil
    }

    Bits.each_bit(other_bits) { |index_m, bit_m|
      bits_minus_m = other_bits & ~bit_m
      m_distance = distances[index_m]
      bests.each { |best_type, best|
        this_cost = best[:cost][index_m][bits_minus_m] + m_distance
        if best[:accept][this_cost, best[:current_cost]]
          best[:current_cost] = this_cost
          best[:current_prev] = index_m
        end
      }
    }

    bests.each_with_object({}) { |(best_type, best), answers|
      answers[best_type] = {
        cost: best.delete(:current_cost),
        prev: best.delete(:current_prev),
      }
    }
  end
end

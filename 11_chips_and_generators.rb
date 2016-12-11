require 'set'

module Floor; refine Array do
  def chips_and_gens
    group_by(&:first).values_at(:chip, :gen).map { |l|
      (l || []).map(&:last)
    }
  end
end end

module State; refine Array do
  def moves(elevator)
    items = self[elevator]
    destinations = [elevator - 1, elevator + 1].select { |f| 0 <= f && f < size }
    (items.combination(2).to_a + items.map { |item| [item] }).flat_map { |moved|
      destinations.map { |dest| [moved, dest, moved.size * (dest - elevator)] }
    }
  end

  def pairs
    each_with_index.with_object(Hash.new { |h, k|
      h[k] = {gen: nil, chip: nil}
    }) { |(items, floor), h|
      items.each { |type, element| h[element][type] = floor }
    }.values.map { |p| p.values_at(:gen, :chip).freeze }.sort.freeze
  end

  using Floor

  def legal?
    all? { |contents|
      chips, gens = contents.chips_and_gens
      gens.empty? || (chips - gens).empty?
    }
  end
end end

using State
using Floor

def moves_to_assemble(input, verbose: false)
  input.each { |contents| contents.each(&:freeze) }

  # moves, state, floor
  move_queue = [[0, input, 0]]

  # state, floor
  seen = Set.new([input.pairs, 0])

  max_moves = 0

  while (a = move_queue.shift)
    moves_so_far, state, elevator = a

    if moves_so_far > max_moves
      puts "#{moves_so_far} moves: #{move_queue.size + 1} states" if verbose
      max_moves = moves_so_far
    end

    best_positive = 0
    best_negative = -1.0 / 0.0

    state.moves(elevator).sort_by(&:last).reverse_each { |moved_items, floor_moved_to, rating|
      # If you're higher than the highest *consecutive* empty floor,
      # you probably don't want to move things into it.
      next if floor_moved_to == state.find_index(&:any?) - 1

      # If I've already gotten better moves out, bail.
      next if (rating > 0 ? best_positive : best_negative) > rating

      # Don't move a pair down.
      # NOPE this fails to find the answer on this input!!!
      # The first floor contains a A generator and a A-compatible microchip.
      # The second floor contains a B generator, a C generator, and a D generator.
      # The third floor contains a B-compatible microchip, a C-compatible microchip, and a D-compatible microchip.
      # The fourth floor contains nothing relevant.
      #chips, gens = moved_items.chips_and_gens
      #next unless floor_moved_to > elevator || (chips & gens).empty?

      new_state = state.map.with_index { |items, floor|
        next items + moved_items if floor == floor_moved_to
        next items - moved_items if floor == elevator
        items
      }

      return moves_so_far + 1 if new_state[0..-2].all?(&:empty?)
      next unless new_state.legal?

      # Set ratings BEFORE pruning seen states.
      # If you can reach a seen state with a +2 move,
      # you don't need to bother with any +1 move!
      best_positive = rating if rating > 0
      best_negative = rating if rating < 0

      # MOST IMPORTANT OPTIMISATION: ALL PAIRS ARE INTERCHANGEABLE
      state_pairs = new_state.pairs
      next if seen.include?([state_pairs, floor_moved_to])
      seen.add([state_pairs, floor_moved_to])

      move_queue << [moves_so_far + 1, new_state, floor_moved_to]
    }
  end
end

def has_flag?(flag)
  ARGV.any? { |a| a.start_with?(?-) && a.include?(flag) }
end

verbose = has_flag?(?v)
part_1_only = has_flag?(?1)
ARGV.reject! { |a| a.start_with?(?-) }

input = ARGF.map { |l|
  [
    [:gen, /(\w+) generator/],
    [:chip, /(\w+)-compatible microchip/],
  ].flat_map { |type, regex|
    l.scan(regex).map { |x| [type, x[0].to_sym].freeze }
  }.freeze
}.freeze

puts moves_to_assemble(input, verbose: verbose)

input = ([input[0] + [:gen, :chip].flat_map { |type|
  [:elerium, :dilithium].map { |element| [type, element].freeze }
}] + input[1..]).freeze

# for the example input,
# adding the two generators to floor 1 would immediately fry the two chips there,
# so there's no point in doing part 2 for the example input
puts moves_to_assemble(input, verbose: verbose) unless part_1_only

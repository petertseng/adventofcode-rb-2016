CHIP = 0
GENERATOR = 1
TYPE_NAMES = %w(chip gen)
TYPE_BITS = 1
TYPE_MASK = (1 << TYPE_BITS) - 1

alias Element = UInt8
alias Component = UInt8

START_FLOOR = begin
  arg = ARGV.find { |x| x.starts_with?('-') && x.includes?('s') }
  # No need to delete here, will get deleted later.
  arg ? arg[(arg.index('s').not_nil! + 1)..-1].to_i : 0
end

class Array
  def moves(elevator)
    items = self[elevator]

    chips, gens = items.partition { |x| x & TYPE_MASK == CHIP }

    # We can't move an A chip and B generator together,
    # because the A chip will certainly get fried.
    # So, our choices for twos: two chips or two generators or a pair.

    # If there is a pair, it doesn't matter which one.
    paired_chip = chips.find { |c| gens.includes?(c | GENERATOR) }
    pair = paired_chip && [paired_chip, paired_chip | GENERATOR]

    unpaired_gens = gens.reject { |g| chips.includes?(g & ~GENERATOR) }

    # If there's a paired generator plus any other,
    # we can't move the paired generator out alone.
    movable_gens1 = (gens.size == 1 ? gens : unpaired_gens)

    # Considerations for moving two generators:
    # If there are two generators, we can always move them both out.
    # If there is one generator, combination(2) will be empty.
    # If there are 3+ generators, no paired generator can move.
    movable_gens2 = gens.size == 2 ? [gens] : unpaired_gens.combinations(2).to_a

    destinations = [elevator - 1, elevator + 1].select { |f| 0 <= f && f < size }

    destinations.flat_map { |dest|
      dest_chips, dest_gens = self[dest].partition { |x| x & TYPE_MASK == CHIP }
      unpaired_chips = dest_chips.reject { |c|
        dest_gens.includes?(c | GENERATOR)
      }

      # If the destination floor has generators,
      # we can only move the corresponding chips in.
      movable_chips = dest_gens.empty? ? chips : chips.select { |c|
        dest_gens.includes?(c | GENERATOR)
      }

      dest_gens1, dest_gens2 =
        case unpaired_chips.size
        when 0; {movable_gens1, movable_gens2}
        when 1
          gen = unpaired_chips[0] | GENERATOR
          # We must move the unpaired chip's generator in.
          movable_by_itself = movable_gens1.includes?(gen)
          {
            # That generator can move in by itself if it was movable by itself.
            movable_by_itself ? [gen] : [] of Component,
            # Moves for which that generator can move in with another:
            if movable_by_itself
              if gens.size == 2
                # Note that the other generator may not have been movable by itself:
                # It may have been a pair on the source floor,
                # in which case moving it by itself would cause its chip to fry,
                # but moving both the generators together solves that problem.
                [gens]
              else
                # move it with all the other gens that would have been movable by themselves.
                (movable_gens1 - [gen]).map { |g| [g, gen] }
              end
            else
              [] of Array(Component)
            end
          }
        when 2
          needed_gens = unpaired_chips.map { |c| c | GENERATOR }
          # We must move both unpaired chips' generators in.
          # They are unpaired on the source floor,
          # so this does not conflict with the above logic for movable_gens2.
          {
            [] of Component,
            needed_gens.all? { |g| gens.includes?(g) } ? [needed_gens] : [] of Array(Component),
          }
        else
          # No matter what we do, no generators are moving to this floor.
          {[] of Component, [] of Array(Component)}
        end

      two_choices = movable_chips.combinations(2).to_a + dest_gens2
      one_choices = movable_chips + dest_gens1

      # If there are unpaired chips, the pair's generator will fry them.
      two_choices << pair if pair && unpaired_chips.empty?

      (two_choices + one_choices.map { |item| [item] }).map { |moved|
        {moved, dest, moved.size * (dest - elevator)}
      }
    }
  end

  def pairs
    h = Hash(Component, UInt8).new(0_u8)
    each_with_index { |items, floor|
      items.each { |item|
        # h's key is the element of the item.
        # The value is (generator_floor << size) | chip_floor
        # Left-shift by log_2(size) would work too,
        # but that's more work to calculate.
        h[item >> TYPE_BITS] |= floor << (item & TYPE_MASK) * size
      }
    }
    h.values.sort
  end

  def move(moved_items, from, to)
    map_with_index { |items, floor|
      next items + moved_items if floor == to
      next items - moved_items if floor == from
      items
    }
  end
end

def moves_to_assemble(input, verbose = false, list_moves = false)
  # moves, state, floor
  move_queue = [{0, input, START_FLOOR}]

  # [state, floor] -> [state, floor, moved_items]
  backtrack = { {input.pairs, START_FLOOR} => {input.pairs, 0, [] of Component}}
  prev = Set.new([{input.pairs, START_FLOOR}])

  max_moves = 0

  until move_queue.empty?
    moves_so_far, state, elevator = move_queue.shift

    if moves_so_far > max_moves
      puts "#{moves_so_far} moves: #{move_queue.size + 1} states" if verbose
      max_moves = moves_so_far
    end

    best_positive = 0
    best_negative = -1.0 / 0.0

    cleared_floor = state.index(&.any?).not_nil! - 1

    state.moves(elevator).sort_by(&.last).reverse_each { |moved_items, floor_moved_to, rating|
      # If you're higher than the highest *consecutive* empty floor,
      # you probably don't want to move things into it.
      next if floor_moved_to == cleared_floor

      # If I've already gotten better moves out, bail.
      next if (rating > 0 ? best_positive : best_negative) > rating

      new_state = state.move(moved_items, from: elevator, to: floor_moved_to)

      if new_state[0..-2].all?(&.empty?)
        return [nil] * (moves_so_far + 1) unless list_moves

        state_pair = state.pairs
        floor = elevator

        prev_moves = moves_so_far.times.map {
          old_state, old_floor, moved = backtrack[{state_pair, floor}]

          state_pair = old_state
          {moved, floor}.tap { floor = old_floor }
        }.to_a

        return prev_moves.reverse << {moved_items, floor_moved_to}
      end

      # Set ratings BEFORE pruning seen states.
      # If you can reach a seen state with a +2 move,
      # you don't need to bother with any +1 move!
      best_positive = rating if rating > 0
      best_negative = rating if rating < 0

      # MOST IMPORTANT OPTIMISATION: ALL PAIRS ARE INTERCHANGEABLE
      prev_key = {new_state.pairs, floor_moved_to}
      next if prev.includes?(prev_key)
      prev.add(prev_key)
      backtrack[prev_key] = {state.pairs, elevator, moved_items} if list_moves

      move_queue << {moves_so_far + 1, new_state, floor_moved_to}
    }
  end
end

def has_flag?(flag)
  ARGV.any? { |a| a.starts_with?('-') && a.includes?(flag) }
end

verbose = has_flag?('v')
part_1_only = has_flag?('1')
list = has_flag?('l')
show_state = has_flag?("ll")

solve = ->(input : Array(Array(Component)), elements : Hash(String, Element)) {
  element_names = elements.to_a.sort_by(&.last).map(&.first)
  name = ->(i : Component) {
    "#{element_names[i >> TYPE_BITS]} #{TYPE_NAMES[i & TYPE_MASK]}"
  }
  moves = moves_to_assemble(input, verbose: verbose, list_moves: list)
  if !moves
    puts "impossible"
    return
  end
  puts moves.size
  if list || show_state
    state = input
    floor = START_FLOOR
    moves.each_with_index { |m, i|
      moved_items, floor_moved_to = m.not_nil!
      puts "#{i + 1}: #{moved_items.map(&name)} -> #{floor_moved_to}" if list
      state = state.move(moved_items, from: floor, to: floor_moved_to)
      floor = floor_moved_to
      if show_state
        state.reverse_each.with_index { |items, distance_from_top|
          puts "#{state.size - distance_from_top}: #{items.map(&name)}"
        }
        puts
      end
    }
  end
}

ARGV.reject! { |a| a.starts_with?('-') }

elements = {} of String => Element

input = ARGF.each_line.map { |l|
  {
    {GENERATOR, /(\w+) generator/},
    {CHIP, /(\w+)-compatible microchip/},
  }.flat_map { |type, regex|
    l.scan(regex).map { |x|
      element = elements[x[1]] ||= elements.size.to_u8
      element << TYPE_BITS | type
    }.to_a
  }
}.to_a

solve.call(input, elements)

input[0].concat((0_u8...4_u8).map { |x| x + (elements.size << TYPE_BITS) })
%w(elerium dilithium).each { |e| elements[e] = elements.size.to_u8 }

# for the example input,
# adding the two generators to floor 1 would immediately fry the two chips there,
# so there's no point in doing part 2 for the example input
solve.call(input, elements) unless part_1_only

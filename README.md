# adventofcode-rb-2016

[![Build Status](https://travis-ci.org/petertseng/adventofcode-rb-2016.svg?branch=master)](https://travis-ci.org/petertseng/adventofcode-rb-2016)

I'm reluctantly doing [Advent of Code](http://adventofcode.com) again.

I say "reluctantly" because I got dragged into it by a friend midway through last year, and felt the need to follow through.

Despite this, I still intend to compete for fast times on the leaderboards.

All solutions are written in Ruby.

The solutions are written with the following goals, with the most important goal first:

1. **Speed**.
   Where possible, use efficient algorithms for the problem.
   Solutions that take more than a second to run are treated with high suspicion.
   This need not be overdone; micro-optimisation is not necessary.
   (In problems where significant hashing is required, hash results may be pre-computed to save time in Travis CI)
2. **Readability**.
3. **Less is More**.
   Whenever possible, write less code.
   Especially prefer not to duplicate code.
   This helps keeps solutions readable too.

# Input

In general, all solutions can be invoked in both of the following ways:

* Without command-line arguments, takes input on standard input.
* With command-line arguments, reads input from the named files (- indicates standard input).

Some may additionally support other ways:

* 1 (Manhattan Distance): Pass the entire sequence of instructions as a single argument in ARGV.
* 5 (MD5 Door): Pass the door ID in ARGV.
  Due to long running time, by default the indices generating five zeroes have been pre-computed for the default door ID.
  To redo the computation (necessary if using a different ID), pass the `-r` flag.
* 8 (Two-Factor Authentication): The `-w` flag may be used to change the width of the screen.
* 9 (Compression): Pass the compressed text in ARGV.
* 11 (Chips and Generators): The `-t` flag uses the test input.
  The `-s` flag can be used to set the starting floor.
  The `-l` flag lists the moves in the solution.
  Using the flag twice (`ll`) lists each floor state in the solution.
  The `-v` flag causes queue size counts to be printed at every move count.
* 13 (Maze): The `-t` flag uses the test input and goal.
  Otherwise, pass the office designer's favourite number on ARGV.
  Changing the goal is not supported.
  The `-f` flag causes the flood-fill to be printed out.
* 14 (One-Time Pad): Pass the salt in ARGV.
  Due to long running time, the hashes have been precomputed.
  To redo the computation, pass the `-r` flag.
* 16 (Dragon Checksum): Pass the initial state in ARGV.
* 17 (MD5 Maze): Pass the passcode in ARGV.
* 18 (It's a Trap!): Pass the first row in ARGV.
* 19 (Josephus): Pass the number of elves in ARGV.
* 22 (Grid Computing): To show the map, use the `-m` flag.

# Highlights

Solutions with interesting algorithmic choices:

* 11 (Chips and Generators):
  Plain breadth-first search, but pruning equivalent states since all generator-microchip pairs are indistinguishable from one another.
  I [explained on Reddit](https://www.reddit.com/r/adventofcode/comments/5hoia9/2016_day_11_solutions/db1v1ws/).
  Note that there are [implementations](https://www.reddit.com/r/adventofcode/comments/5i1blt/2016_day_11_c_both_parts_in_10_milliseconds/) using even more compact representations that allow bitwise operations to check move legality.
* 15 (Timing Discs):
  Modular arithmetic, using modular inverses to determine how far each disc must spin, and noting that further alignments only happen at the LCM of the periods.
* 16 (Dragon Checksum):
  Every full (input + input reversed and negated) pair is known to increase the number of ones by exactly the size of the input, so the only things left are to deal with partial chunks and to calculate the parity of the Dragon sequence.
  I [discussed on Reddit](https://www.reddit.com/r/adventofcode/comments/5imh3d/2016_day_16_solutions/db9erfp/), leading to [my method of calculating Dragon parity in O(log n)](https://www.reddit.com/r/adventofcode/comments/5imh3d/2016_day_16_solutions/db9w7im/).
  Before I had even discovered that, askalski had already [taken to the next level](https://www.reddit.com/r/adventofcode/comments/5ititq/2016_day_16_c_how_to_tame_your_dragon_in_under_a/) by finding Dragon parity in O(1) time.
* 18 (It's a Trap!):
  It's left XOR right.
* 19 (Josephus):
  Mostly explained in comments, but it started with me [musing on Reddit](https://www.reddit.com/r/adventofcode/comments/5j4lp1/2016_day_19_solutions/dbdh7i2/) how to determine the winner of N from N - 1 and going from there.
* 21 (Scrambled Passwords):
  Undo each operation rather than brute-forcing. Note that "rotate based on position" is quite interesting.
* 22 (Grid Computing):
 Naively move the empty space to the top, then use math to figure out how many steps it takes to move it to the side, assuming no walls in the top two rows.
* 12, 23, 25 (Assembunny):
  Optimises out sequences of the form:
  * `x += y`
  * `x += y * z`
  * `q, r = x / d, d - (x % d)` (only applicable for 25)

Solutions notable for good leaderboard-related reasons:

* 8 (Two-Factor Authentication): A [leaderboard](http://adventofcode.com/2016/leaderboard/day/8) performance that I have **never** matched since, not even in 2017!

Solutions notable for bad leaderboard-related reasons:

* 7 (IPv7):
  Reading comprehension failure: read "doesn't contain an ABBA in brackets" as "ignore any ABBA in brackets" so falsely accepted `abba[abba]`.
* 12 (Assembunny): Lost time on easy mistakes:
    * Accidentally making decrement increment, because of copy-and-paste coding.
    * Having JNZ do nothing when the register was 0 (just repeatedly executing the same JNZ) instead of advancing the PC.
* 13 (Maze) part 2:
  A silly bug (`wall?(x, y)` instead of `wall?(nx, ny)`) meant walls were visitable but with no neighbours, giving a correct answer for part 1 but an incorrect answer for part 2.
  Significant time loss debugging this, including time lost assuming that I was right and the site was wrong.
  Only found out something was wrong by printing out all visited non-walls with O and realising that the count of Os was different than the visited count that the code reported.
* 14 (One-Time Pad):
  Noted in comments; premature optimisation led to buggy solution.
* 16 (Dragon Checksum) part 2:
  Used string instead of bool.
  Ran out of memory and had to reboot computer.
* 23 (Assembunny II):
  Attempted to use Assembunny to C translator, seeing too late that `tgl` was specifically designed to prevent it.
  [Didn't stop askalski from doing it anyway](https://www.reddit.com/r/adventofcode/comments/5jvbzt/2016_day_23_solutions/dbjbnbl/).
  Assembunny I code was not in reasonable shape to be reused easily.
  Lesson learned: Ensure all code is reasonably extensible.
* 24 (Hamiltonian):
  Used `OPEN[ny, nx]` instead of `OPEN[ny][nx]`, meaning robot was ignoring all walls.
  Once again, assumed I was right and site was wrong.
  Printing out paths robot is taking made this clear.
  Statically-checked types would have helped, since `OPEN[ny, nx]` is of type `[bool]` whereas `OPEN[ny][nx]` is of type `bool`.
  On the bright side, I learn about `array[start, length]` and thus use it intentionally many times in 2017.

# Posting schedule and policy

Before I post my day N solution, the day N leaderboard **must** be full.
No exceptions.

Waiting any longer than that seems generally not useful since at that time discussion starts on [the subreddit](https://www.reddit.com/r/adventofcode) anyway.

Solutions posted will be **cleaned-up** versions of code I use to get leaderboard times (if I even succeed in getting them), rather than the exact code used.
This is because leaderboard-seeking code is written for programmer speed (whatever I can come up with in the heat of the moment).
This often produces code that does not meet any of the goals of this repository (seen in the introductory paragraph).

# Other years' solutions

The [index](https://github.com/petertseng/adventofcode-common/blob/master/index.md) lists all years/languages I've ever done (or will ever do).

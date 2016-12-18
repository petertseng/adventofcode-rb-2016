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

# Posting schedule and policy

Before I post my day N solution, the day N leaderboard **must** be full.
No exceptions.

Waiting any longer than that seems generally not useful since at that time discussion starts on [the subreddit](https://www.reddit.com/r/adventofcode) anyway.

Solutions posted will be **cleaned-up** versions of code I use to get leaderboard times (if I even succeed in getting them), rather than the exact code used.
This is because leaderboard-seeking code is written for programmer speed (whatever I can come up with in the heat of the moment).
This often produces code that does not meet any of the goals of this repository (seen in the introductory paragraph).

# Other years' solutions

The [index](https://github.com/petertseng/adventofcode-common/blob/master/index.md) lists all years/languages I've ever done (or will ever do).

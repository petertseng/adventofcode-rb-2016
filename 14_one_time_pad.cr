require "digest/md5"

WINDOW = 1000
NUM_KEYS = 64

def pads(input, rounds = 0)
  pads = [] of Int32
  stop = 1.0 / 0.0

  triplets = Hash(Char, Array(Int32)).new { |h, k| h[k] = [] of Int32 }

  0.step { |i|
    md5 = Digest::MD5.hexdigest(input + i.to_s)
    rounds.times {
      md5 = Digest::MD5.hexdigest(md5)
    }

    md5.scan(/(.)\1\1\1\1/).each { |(char)|
      candidates = triplets.delete(char[0])
      (candidates || [] of Int32).select { |n| n + WINDOW >= i }.each { |n|
        pads << n
        # Still need to check for any numbers undercutting n.
        stop = n + WINDOW if pads.size == NUM_KEYS
      }
    }

    m = (/(.)\1\1/.match(md5))
    triplets[m[1][0]] << i if m

    return pads.sort if i >= stop
  }

  raise "Unreachable."
end

input = ARGV.first

{0, 2016}.each { |r| puts pads(input, rounds = r)[NUM_KEYS - 1] }

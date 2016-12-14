require 'digest'

WINDOW = 1000
NUM_KEYS = 64

def pads(inputs)
  pads = []
  stop = 1.0 / 0.0

  triplets = Hash.new { |h, k| h[k] = [] }

  0.step { |i|
    md5 = inputs[i]

    md5.scan(/(.)\1\1\1\1/).each { |(char)|
      candidates = triplets.delete(char)
      candidates.select { |n| n + WINDOW >= i }.each { |n|
        pads << n
        # Still need to check for any numbers undercutting n.
        stop = n + WINDOW if pads.size == NUM_KEYS
      }
    }

    m = (/(.)\1\1/.match(md5))
    triplets[m[1]] << i if m

    return pads.sort if i >= stop
  }
end

real = ARGV.delete('-r')
input = (!ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read).freeze

f2017 = ->i {
  s = input + i.to_s
  2017.times { s = Digest::MD5.hexdigest(s) }
  s
}
if !real
  precomputed_file = "#{__dir__}/hashes/md5-2017-#{Digest::SHA256.hexdigest(input)}"
  f2017 = File.readlines(precomputed_file) if File.exist?(precomputed_file)
end

[
  ->i { Digest::MD5.hexdigest(input + i.to_s) },
  f2017,
].each { |f| puts pads(f)[NUM_KEYS - 1] }

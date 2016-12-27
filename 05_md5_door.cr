require 'digest'

real = ARGV.delete('-r')
input = !ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read
zeroes = '00000'.freeze

pass = ''
pass2 = [nil] * 8

is = 0.step
if !real
  # So as not to make Travis run forever:
  # Indices producing 5 zeroes are precomputed.
  precomputed_file = "#{__dir__}/hashes/zeroes-#{Digest::SHA256.hexdigest(input)}"
  is = File.readlines(precomputed_file).map(&:chomp) if File.exist?(precomputed_file)
end

is.each { |i|
  md5 = Digest::MD5.hexdigest(input + i.to_s)
  next unless md5.start_with?(zeroes)
  puts i if real
  pass << md5[5]
  puts pass if pass.size == 8

  pos = Integer(md5[5], 16)
  if 0 <= pos && pos < 8 && pass2[pos].nil?
    pass2[pos] = md5[6]
    break unless pass2.any?(&:nil?)
  end
}
puts pass2.join

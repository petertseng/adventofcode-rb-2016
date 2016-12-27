require "digest/md5"

input = ARGV.first

pass = ""
pass2 = Array(Char?).new(8, nil)

is = 0.step

is.each { |i|
  md5 = Digest::MD5.hexdigest(input + i.to_s)
  next unless md5[0...5] == "00000"
  pass += md5[5]
  puts pass if pass.size == 8

  pos = md5[5].to_i(base: 16)
  if 0 <= pos && pos < 8 && pass2[pos].nil?
    pass2[pos] = md5[6]
    break unless pass2.any?(&.nil?)
  end
}
puts pass2.join

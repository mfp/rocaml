
require 'tree'

s = StringSet.new
puts "1"
p s.include?("foo")
puts "2"
s = s.add("foo")
p s.include?("foo")
%w[bar foobar baz b barbaz bazbar].each do |x|
  s = s.add x
  p s.dump
end

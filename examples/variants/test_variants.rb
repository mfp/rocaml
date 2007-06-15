
module Variants; end # namespace
require 'variants'

Foo = 0
Bar = 1
Baz = 2
Foobar = 0
Barbaz = 1

Variant = Variants::DummyBase

o = Variant.new
p o
p o.kind
o.kind = Bar
p o.kind
puts "non-constant constructors"
o.kind = [Barbaz, [42, "whatever"]]
puts "checking"
p o.kind
o.kind = [Foobar, ["string"]]
p o.kind

puts "Testing tuples"
o = Variants::DummyBase.new
p o.tuple
o.send_tuple [13, Baz, "some string"]

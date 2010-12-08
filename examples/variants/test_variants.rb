## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

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
o.kind = [Foobar, "string"]
p o.kind

puts "Testing tuples"
o = Variants::DummyBase.new
p o.tuple
o.send_tuple [13, Baz, "some string"]

puts "Testing symbolic variants"
include Variants
p SymbolicVariants.identity(:Baz)
p SymbolicVariants.identity(:Bar)
p SymbolicVariants.identity(:Foo)
p SymbolicVariants.identity([:Foobar, "this is Foobar"])
p SymbolicVariants.identity([:Barbaz, [42, "this is Barbaz"]])
p SymbolicVariants.identity([:Babar, [["foo", "bar", "baz"]]])

puts "Now a type error that should be detected..."
p SymbolicVariants.identity([:Barbaz, "this is not Foobar"])

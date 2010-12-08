## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

require 'fast_marshal'
require 'benchmark'

Vector = Struct.new(:x, :y, :z)

SERIALIZATION_TESTS = {
  "vector_array" => [200000,   lambda{|i| Vector.new(i, 1.5 * i, 4.2 * i) }],
  "int_array"    => [1000000, lambda{|i| i}],
  "string_array" => [100000,  lambda {|i| "str%5d" % i}],
}

SERIALIZATION_TESTS.each do |name, (num_values, func)|
  arr = (0...num_values).map(&func)

  s1 = s2 = nil

  Benchmark.bm(30) do |bm|
    bm.report("Marshal#dump"){ s1 = Marshal.dump(arr) }
    bm.report("FastMarshal#dump_#{name}"){ s2 = FastMarshal.send("dump_#{name}", arr) }
  end

  puts

  Benchmark.bm(30) do |bm|
    bm.report("Marshal#load"){ Marshal.load(s1) }
    bm.report("FastMarshal#load_#{name}"){ FastMarshal.send("load_#{name}", s2) }
  end

  puts <<-EOF
  Sizes:
  Marshal      #{s1.size}
  FastMarshal  #{s2.size}
  EOF

  #p Marshal.load(s1).last
  #p FastMarshal.load_vector_array(s2).last
end



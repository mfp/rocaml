
require 'fast_marshal'
require 'benchmark'

Vector = Struct.new(:x, :y, :z)

arr = (0..20000).map{|i| Vector.new(i, 1.5 * i, 4.2 * i)}

s1 = s2 = nil

Benchmark.bm(30) do |bm|
  bm.report("Marshal#dump"){ s1 = Marshal.dump(arr) }
  bm.report("FastMarshal#dump_vector_array"){ s2 = FastMarshal.dump_vector_array(arr) }
end

puts

Benchmark.bm(30) do |bm|
  bm.report("Marshal#load"){ Marshal.load(s1) }
  bm.report("FastMarshal#load_vector_array"){ FastMarshal.load_vector_array(s2) }
end

puts <<EOF
Sizes:
Marshal      #{s1.size}
FastMarshal  #{s2.size}

EOF

p Marshal.load(s1).last
p FastMarshal.load_vector_array(s2).last



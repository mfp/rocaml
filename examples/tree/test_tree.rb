
require 'tree'

s = StringSet.new
p s.include?("foo")
s = s.add("foo")
p s.include?("foo")

s2 = StringRBSet.new
s2 = s2.add("foo")

p s.dump
p s2.dump
%w[bar bar foobar baz b barbaz bazbar].each do |x|
  s = s.add x
  s2 = s2.add x
  p s.dump
  p s2.dump
end

begin
  require 'benchmark'
  require 'rbtree'

  range  = 50000
  nitems = 100000

  rb = RBTree.new
  s  = StringRBSet.new
  s2 = StringSet.new

  puts "\n\nComparing with RBTree just for laughs!!\n\n"

  items = (0...nitems).map{|x| rand(range).to_s}
  Benchmark.bm(25) do |bm|
    bm.report("nop iteration"){ items.each{|x| }}
    bm.report("RBTree insert"){ items.each{|x| rb[x] = true } }
    bm.report("IntRBSet insert"){ items.each{|x| s = s.add(x) } }
    bm.report("IntSet insert"){ items.each{|x| s2 = s2.add(x) } }
  end

  puts

  items2 = (0...nitems).map{|x| rand(range).to_s}
  Benchmark.bmbm(22) do |bm|
    bm.report("nop iteration"){ items2.each{|x| }}
    bm.report("RBTree lookup"){ items2.each{|x| rb[x.to_s]} }
    bm.report("IntRBSet lookup"){ items2.each{|x| s.include?(x)} }
    bm.report("IntSet lookup"){ items2.each{|x| s2.include?(x)} }
  end

  puts <<-EOF

* RBTree uses #<=> to compare objects, RBSet and SimpleSet use OCaml's
  polymorphic compare. However, whereas RBTree uses Ruby objects (VALUEs), each
  lookup with RBSet and SimpleSet involves a Ruby -> OCaml conversion
* RBSet and SimpleSet must convert the Ruby object given to #add into an OCaml
  value. RBTree just reuses it.
* since RBSet and SimpleSet make a copy of the object being inserted, changing
  the GC parameters will greatly affect performance; for instance, running with
  OCAMLRUNPARAM=h=6M makes insertions 30% faster
* SimpleSet and RBSet are not optimized at all; the former takes 15 LoCs, the
  latter 25! RBSet weighs about 3000 LoCs, but provides of course much more
  functionality. However, the functions to create a RB tree, insert and find a
  node alone take nearly 200 lines.
  EOF

rescue LoadError
end


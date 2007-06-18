require 'records.so'

p Records.test_record(:a => 1, :b => "foo", :c => 42)
p Records.add_vector({:x => 1, :y => 2, :z => 3},
                     {:x => 10, :y => 20, :z => 30})

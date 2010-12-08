## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

require 'records.so'

p Records.test_record(:a => 1, :b => "foo", :c => 42)
p Records.add_vector({:x => 1, :y => 2, :z => 3},
                     {:x => 10, :y => 20, :z => 30})

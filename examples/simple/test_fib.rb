## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

require 'fib.so'

p Fib.fib(10)
p Fib.fib_range(10, 20)

p Fib.fib_range_s(10, 20)

p Fib.fib_range_plus(10, 20, (0..10).map{|i| 0.1 * i})

p Conversions.sum_int_array(1..10)
p Conversions.sum_arrays(0..10, 100..110)
p Conversions.sum_vectors([1, 42, -1], [0.1, -0.9, 10])

p Conversions.raise_if_negative(1)
puts "Testing exceptions raised in OCaml..."
p Conversions.raise_if_negative(-1)

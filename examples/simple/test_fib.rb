require 'fib.so'

p Fib.fib(10)
p Fib.fib_range(10, 20)

p Fib.fib_range_s(10, 20)

p Fib.fib_range_plus(10, 20, (0..10).map{|i| 0.1 * i})

p Fib.raise_if_negative(1)
p Fib.raise_if_negative(-1)

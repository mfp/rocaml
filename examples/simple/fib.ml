
let rec fib n =
    if n < 2 then 1
      else (fib (n-1)) + (fib(n-2))

let fib_map first last =
  Array.init (last - first + 1) (fun i -> fib (first + i))

let fib_map_s first last =
  Array.map string_of_int (fib_map first last)


exception NegativeNumber of int

let raise_if_negative num =
  if num < 0 then raise (NegativeNumber num)

open Callback
let _ =
  register "Fib.fib" fib;
  register "Fib.fib_map" fib_map;
  register "Fib.fib_map_s" fib_map_s;
  register "Fib.raise_if_negative" raise_if_negative



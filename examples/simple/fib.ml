open Printf

let rec fib n =
    if n < 2 then 1
      else (fib (n-1)) + (fib(n-2))

let fib_range first last =
  Array.init (last - first + 1) (fun i -> fib (first + i))

let fib_range_s first last =
  Array.map string_of_int (fib_range first last)

let fib_range_plus first last arr =
  printf "fib_range_plus %d -- %d\n" first last;
  printf "arr: %s\n"
    ("[" ^
     String.concat ", " (Array.to_list (Array.map string_of_float arr))
     ^ "]");
  Array.mapi (fun i x -> float_of_int x +. arr.(i)) (fib_range first last)

open Callback
let _ =
  register "Fib.fib" fib;
  register "Fib.fib_range" fib_range;
  register "Fib.fib_range_s" fib_range_s;
  register "Fib.fib_range_plus" fib_range_plus;


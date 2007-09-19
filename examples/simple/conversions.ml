
open Printf

let sum_int_array a =
  printf "sum_int_array got [%s]\n%!"
    (String.concat ", " (Array.to_list (Array.map string_of_int a)));
  Array.fold_left (fun s x -> s + x) 0 a

let sum_vectors (x, y, z) (x', y', z') = (x +. x', y +. y', z +. z')

let sum_arrays a b =
  Array.init (min (Array.length a) (Array.length b)) (fun i -> a.(i) +. b.(i))

exception NegativeNumber of int

let raise_if_negative num =
  if num < 0 then raise (NegativeNumber num)

export sum_int_array, sum_vectors, sum_arrays, raise_if_negative

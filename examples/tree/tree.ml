open Printf

type 'a t =
    Empty
  | Node of 'a t * 'a * 'a t

let empty = Empty

let rec add x = function
    Empty -> Node (Empty, x, Empty)
  | Node (l, y, r) ->
      printf "REC add %s\n" x;
      if x < y then Node(add x l, y, r) else Node(l, y, add x r)

let rec mem x = function
    Empty -> false
  | Node(l, y, r) when x = y -> true
  | Node(l, y, r) -> if x < y then mem x l else mem x r

let identity x = x

let add' t x = add x t
let mem' t x = mem x t

open Callback
let _ =
  register "StringSet.empty" (fun () -> empty);
  register "IntSet.empty" (fun () -> empty);
  register "IntSet.add" add';
  register "IntSet.mem" mem';
  register "StringSet.add" add';
  register "StringSet.mem" mem';
  register "StringSet.dump" identity

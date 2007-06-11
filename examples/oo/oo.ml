open Printf

type t = { mutable value : int; whatever : string }

let of_string s =
  { value = int_of_string s; whatever = "foo" }

let create n =
  { value = n; whatever = "foo" }

let inc t =
  printf "INC\n%!";
  t.value <- t.value + 1

let dec t =
  printf "DEC\n%!";
  t.value <- t.value - 1

let get t = t.value

open Callback
let _ =
  register "Oo.new_from_string" of_string;
  register "Oo.new" create;
  register "Oo.inc" inc;
  register "Oo.dec" dec;
  register "Oo.get" get


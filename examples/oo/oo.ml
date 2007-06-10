
type t = { mutable value : int; whatever : string }

let of_string s =
  { value = int_of_string s; whatever = "foo" }

let create n =
  { value = n; whatever = "foo" }

let inc t = t.value <- t.value + 1

let get t = t.value

open Callback
let _ =
  register "Oo.new_from_string" of_string;
  register "Oo.new" create;
  register "Oo.inc" inc;
  register "Oo.get" get


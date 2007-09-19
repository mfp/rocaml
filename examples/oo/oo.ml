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

(* the default namespace is the current module name, so the following isn't
 * actually needed *)
(* namespace "Oo" *)

export create, inc, dec, get
export (of_string) aliased "new_from_string"

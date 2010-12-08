(*
 * rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
 *                                http://eigenclass.org
 * Use and redistribution subject to the same conditions as Ruby.
 * See the LICENSE file included in rocaml's distribution for more
 * information.
 *)

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

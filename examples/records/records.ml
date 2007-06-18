open Printf

type t1 = { a : int; b : string; c : float }

let test_record t =
  printf "This is OCaml, got {a = %d; b = '%s'; c = %f}\n%!" t.a t.b t.c;
  { a = t.a * 2; b = t.b ^ t.b; c = 2.0 *. t.c }

open Callback
let _ =
  register "Records.test_record" test_record


open Printf

type t1 = { a : int; b : string; c : float }

let test_record t =
  printf "This is OCaml, got {a = %d; b = '%s'; c = %f}\n%!" t.a t.b t.c;
  { a = t.a * 2; b = t.b ^ t.b; c = 2.0 *. t.c }

type vector = { x : float; y : float; z : float }

let add_vector a b = { x = a.x +. b.x; y = a.y +. b.y; z = a.z +. b.z}

(* if not specified, the namespace is the current module name
 * (capitalized filename) *)

(* namespace "Records" *)
export test_record, add_vector


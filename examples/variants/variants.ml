open Printf

type kind = Foo | Bar | Baz

type t = { mutable kind : kind }

let string_of_kind = function
    Foo -> "Foo"
  | Bar -> "Bar"
  | Baz -> "Baz"

let create kind = { kind = Foo }

let get_kind t = t.kind

let set_kind t k =
  printf "set kind to %s\n" (string_of_kind k);
  t.kind <- k

open Callback
let _ =
  register "DummyBase.create" create;
  register "DummyBase.get_kind" get_kind;
  register "DummyBase.set_kind" set_kind


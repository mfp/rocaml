(*
 * rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
 *                                http://eigenclass.org
 * Use and redistribution subject to the same conditions as Ruby.
 * See the LICENSE file included in rocaml's distribution for more
 * information.
 *)

open Printf

type kind = Foo | Bar | Baz | Foobar of string | Barbaz of int * string | Babar of string list

type t = { mutable kind : kind }

let string_of_kind = function
    Foo -> "Foo"
  | Bar -> "Bar"
  | Baz -> "Baz"
  | Foobar s -> sprintf "Foobar \"%s\"" s
  | Barbaz (i, s) -> sprintf "Barbaz (%d, \"%s\")" i s
  | Babar l -> sprintf "Babar [%s]" (String.concat ";" (List.map String.escaped l))

let create kind = { kind = Foo }

let get_kind t = t.kind

let set_kind t k =
  printf "set kind to %s\n%!" (string_of_kind k);
  t.kind <- k

let tuple t = (42, t.kind, "foo")

let send_tuple t (n, kind, s) =
  printf "got (%d, %s, '%s')\n%!" n (string_of_kind kind) s

let identity kind =
  printf "got %s\n%!" (string_of_kind kind);
  kind

namespace "DummyBase"
export create, get_kind, set_kind, tuple, send_tuple

namespace "SymbolicVariants"
export identity

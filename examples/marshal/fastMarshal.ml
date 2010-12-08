(*
 * rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
 *                                http://eigenclass.org
 * Use and redistribution subject to the same conditions as Ruby.
 * See the LICENSE file included in rocaml's distribution for more
 * information.
 *)

type vector = { x : float; y : float; z : float }

let dump x = Marshal.to_string x [Marshal.No_sharing]

let load s = Marshal.from_string s 0

(* the default namespace is the current module name, so the following isn't
 * actually needed *)
namespace "FastMarshal"

export dump, load

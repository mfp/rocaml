
type vector = { x : float; y : float; z : float }

let verbose = false

let printf =
  if verbose then Printf.printf
  else (fun x y -> ())

let dump_vector_array x =
  printf "Got array of size %d\n" (Array.length x);
  let r = Marshal.to_string x [] in
    printf "Returning serialized array (%d bytes)\n%!" (String.length r);
    r

let load_vector_array s =
  printf "Got string of size %d\n%!" (String.length s);
  Marshal.from_string s 0

open Callback
let _ =
  register "FastMarshal.dump_vector_array" dump_vector_array;
  register "FastMarshal.load_vector_array" load_vector_array

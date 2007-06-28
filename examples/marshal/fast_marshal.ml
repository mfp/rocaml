
type vector = { x : float; y : float; z : float }

let dump x = Marshal.to_string x [Marshal.No_sharing]

let load s = Marshal.from_string s 0

open Callback
let _ =
  register "FastMarshal.dump" dump;
  register "FastMarshal.load" load

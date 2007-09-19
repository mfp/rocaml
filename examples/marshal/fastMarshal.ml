
type vector = { x : float; y : float; z : float }

let dump x = Marshal.to_string x [Marshal.No_sharing]

let load s = Marshal.from_string s 0

(* the default namespace is the current module name, so the following isn't
 * actually needed *)
namespace "FastMarshal"

export dump, load

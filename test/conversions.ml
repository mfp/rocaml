
open Printf

let string_of_array f a = "[" ^ String.concat ", " (Array.to_list (Array.map f a)) ^ "]"

module Basic =
struct
  let _ =
    let id x = x in
    let r f name = Callback.register ("Conversions." ^ name) f in
      List.iter (r id) ["bool"; "int"; "float"; "string"; "unit"]
end

module Arrays =
struct
  let bool_array = string_of_array (function true -> "true" | false -> "false")
  let int_array = string_of_array string_of_int
  let float_array = string_of_array string_of_float
  let string_array = string_of_array (fun s -> "\"" ^ s ^ "\"")
  let int_array_array = string_of_array int_array
  let float_array_array = string_of_array float_array

  let _ =
    let r name f = Callback.register ("Conversions." ^ name) f in
      r "bool_array" bool_array;
      r "int_array" int_array;
      r "float_array" float_array;
      r "string_array" string_array;
      r "int_array_array" int_array_array;
      r "float_array_array" float_array_array
end

module Tuples =
struct
  let int_tuple2 (a, b) = sprintf "[%d, %d]" a b
  let float_tuple2 (a, b) = sprintf "[%s, %s]" (string_of_float a) (string_of_float b)
  let int_float_tuple2 (a, b) = sprintf "[%d, %s]" a (string_of_float b)
  let string_tuple2 (a, b) = sprintf "[\"%s\", \"%s\"]" a b

  let _ =
    let r name f = Callback.register ("Conversions." ^ name) f in
      r "int_tuple2" int_tuple2;
      r "float_tuple2" float_tuple2;
      r "int_float_tuple2" int_float_tuple2;
      r "string_tuple2" string_tuple2
end


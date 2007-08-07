
open Printf

let string_of_array f a = "[" ^ String.concat ", " (Array.to_list (Array.map f a)) ^ "]"
let string_of_list f l = "[" ^ String.concat ", " (List.map f l) ^ "]"

module Basic =
struct
  let _ =
    let id x = x in
    let r f name = Callback.register ("Conversions." ^ name) f in
      List.iter (r id) ["bool"; "int"; "big_int"; "float"; "string"; "unit"]
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

module Lists =
struct
  let bool_list = string_of_list (function true -> "true" | false -> "false")
  let int_list = string_of_list string_of_int
  let float_list = string_of_list string_of_float
  let string_list = string_of_list (fun s -> "\"" ^ s ^ "\"")
  let int_list_list = string_of_list int_list
  let float_list_list = string_of_list float_list

  let _ =
    let r name f = Callback.register ("Conversions." ^ name) f in
      r "bool_list" bool_list;
      r "int_list" int_list;
      r "float_list" float_list;
      r "string_list" string_list;
      r "int_list_list" int_list_list;
      r "float_list_list" float_list_list
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
      r "string_tuple2" string_tuple2;
      r "string_int_float_bool_tuple4" (fun x -> x)
end

module AbstractTypes =
struct
  type t1 = { foo : int }
  type t2 = { bar : int }

  let t1 () = { foo = 1 }
  let t2 () = { bar = 1 }

  let f t1 t2 = { foo = t1.foo + t2.foo }

  let g t1 t2 = { bar = t1.bar + t2.bar }

  let _ =
    let r name f = Callback.register name f in
      r "T1.binary_abstract_t1_t1" f;
      r "T2.binary_abstract_t2_t2" g;
      r "T1.make_t1" t1;
      r "T2.make_t2" t2
end

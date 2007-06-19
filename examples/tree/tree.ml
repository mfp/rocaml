open Printf

exception Found

module SimpleSet =
struct
  type 'a t = Empty | Node of 'a t * 'a * 'a t

  let empty = Empty

  let add x t =
    let rec aux x = function
        Empty -> Node (Empty, x, Empty)
      | Node (l, y, r) ->
          if x < y then Node(aux x l, y, r) else if x > y then Node(l, y, aux x r)
          else raise Found
    in try aux x t with Found -> t

  let rec mem x = function
      Empty -> false
    | Node(l, y, r) -> if x < y then mem x l else if x > y then mem x r else true

  let add' t x = add x t
  let mem' t x = mem x t
end

module RBSet =
struct
  type color = R | B
  type 'a t = Empty | Node of color * 'a t * 'a * 'a t

  let empty = Empty

  let rec mem x = function
      Empty -> false
    | Node(_, l, y, r) ->
        if y < x then mem x l else if y > x then mem x r else true

  let balance = function
      B, Node(R, Node(R, a, x, b), y, c), z, d
    | B, Node(R, a, x, Node(R, b, y, c)), z, d
    | B, a, x, Node(R, Node(R, b, y, c), z, d)
    | B, a, x, Node(R, b, y, Node(R, c, z, d)) -> Node(R, Node(B, a, x, b), y, Node(B, c, z, d))
    | (c, a, x, b) -> Node (c, a, x, b)

  let add x t =
    let rec ins = function
        Empty -> Node(R, Empty, x, Empty)
      | Node(color, a, y, b) as n ->
          if x < y then balance (color, ins a, y, b)
          else if x > y then balance (color, a, y, ins b)
          else raise Found
    in try match ins t with
        Node (_, a, y, b) ->  Node(B, a, y, b)
      | Empty -> assert false (* ins always returns Node _ *)
    with Found -> t
end

let identity x = x

open Callback
let _ =
  let def_set t =
    let r1 name f = register (t ^ "Set" ^ "." ^ name) f in
    let r2 name f = register (t ^ "RBSet" ^ "." ^ name) f in
      r1 "empty" (fun () -> SimpleSet.empty);
      r1 "add" SimpleSet.add';
      r1 "mem" SimpleSet.mem';
      r1 "dump" identity;
      r2 "empty" (fun () -> RBSet.empty);
      r2 "add" (fun t x -> RBSet.add x t);
      r2 "mem" (fun t x -> RBSet.mem x t);
      r2 "dump" identity
  in
    List.iter def_set ["Int"; "String"]

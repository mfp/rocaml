
# extension name, XXX in   require 'XXX'
EXT_NAME = "tree"

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# cmxa
CAML_LIBS = %w[]

# list of .cmx (autodetected if empty)
CAML_OBJS = %w[]

# compilation flags
CAML_FLAGS = ""

# -I options (-I must be prepended)
CAML_INCLUDES = %w[]

$:.unshift "../.."

require 'rocaml'

Interface.generate("tree") do |iface|
  string_tree = sym_variant("kind") do |t|
    constant :Empty
    non_constant :Node, TUPLE(t, STRING, t)
  end

  def_class("StringSet") do |c|
    t = c.abstract_type
    fun "empty", UNIT => t, :aliased_as => "new"
    fun "make", string_tree => t

    method "add", [t, STRING] => t
    method "mem", [t, STRING] => BOOL, :aliased_as => "include?"
    method "dump", t => string_tree
  end
end

require 'rocaml_extconf'

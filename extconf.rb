
# extension name, XXX in  require 'XXX'
EXT_NAME = "foo"

# list of .cmx
CAML_OBJS = %w[]

# a .o file that will contain your code and the runtime
CAML_TARGET = %w[]

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# -I options (-I must be prepended)
CAML_INCLUDES = %w[]

# cmxa libraries to use
CAML_LIBS = %[]

# compilation flags
CAML_FLAGS = ""

require 'rocaml'

Interface.generate("foo") do
  def_module("Foo", :under => "Some::NameSpace") do
    # foo : int -> int
    fun "foo", INT => INT
    # bar : int -> int -> int array
    fun "bar", [INT, INT] => ARRAY(INT)
    # baz : int -> int -> string array
    fun "baz", [INT, INT] => ARRAY(STRING)
    # foobar : unit -> int
    fun "foobar", UNIT => INT
    # barbaz : unit -> unit
    fun "barbaz", UNIT => UNIT
  end

  def_class("Bar", :under => "ACME") do |c|
    fun "bar", INT => INT
    fun "create", INT => c.abstract_type
    method "foo", c.abstract_type => INT
    method "bar", [c.abstract_type, INT] => INT
  end
end

require 'rocaml_extconf'

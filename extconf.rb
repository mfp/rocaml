
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

require 'ruby_ocaml'

Interface.generate("foo", :dest => "foo_wrap.c") do
  def_module("Foo", :under => "Some::NameSpace") do
    # foo : int -> int
    fun "foo", INT => INT
    # bar : int -> int -> int array
    fun "bar", [INT, INT] => ARRAY(INT)
    # baz : int -> int -> string array
    fun "baz", [INT, INT] => ARRAY(STRING)
  end
end

require 'ruby_ocaml_extconf'

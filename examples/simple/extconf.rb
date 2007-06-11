
# extension name, XXX in   require 'XXX'
EXT_NAME = "fib"

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# some cmxa; auto-detection?
CAML_LIBS = %[]

# list of .cmx
CAML_OBJS = %w[fib.cmx]

# a .o file that will contain your code and the runtime
CAML_TARGET = %w[fibonacci.o]

# compilation flags
CAML_FLAGS = ""

# -I options (-I must be prepended)
CAML_INCLUDES = %w[]

$:.unshift "../.."

require 'rocaml'

Interface.generate("fib", :dest => "fib_wrap.c") do
  def_module("Fib") do
    fun "fib", INT => INT
    fun "fib_map", [INT, INT] => ARRAY(INT)
    fun "fib_map_s", [INT, INT] => ARRAY(STRING)
    fun "raise_if_negative", INT => UNIT
    fun "inexistent", INT => INT
  end
end

require 'rocaml_extconf'

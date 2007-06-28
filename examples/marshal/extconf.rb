
# extension name, XXX in   require 'XXX'
EXT_NAME = "fast_marshal"

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# cmxa
CAML_LIBS = %w[]

# list of .cmx (autodetected if empty)
CAML_OBJS = %w[]

# compilation flags
CAML_FLAGS = ""

# -I options (-I must be prepended) e.g. ["-I ../lib"]
CAML_INCLUDES = []

$:.unshift "../.."

require 'rocaml'

Interface.generate("fast_marshal") do
  vector_t = RECORD([:x, :y, :z], [FLOAT, FLOAT, FLOAT])

  def_class("FastMarshal") do |c|
    fun "dump_vector_array", ARRAY(vector_t) => STRING
    fun "load_vector_array", STRING => ARRAY(vector_t)
  end
end

require 'rocaml_extconf'

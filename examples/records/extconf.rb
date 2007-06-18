
# extension name, XXX in   require 'XXX'
EXT_NAME = "records"

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# some cmxa; auto-detection?
CAML_LIBS = %w[]

# list of .cmx (autodetected if empty)
CAML_OBJS = %w[]

# compilation flags
CAML_FLAGS = ""

# -I options (-I must be prepended)
CAML_INCLUDES = %w[]

$:.unshift "../.."

require 'rocaml'

Interface.generate("records") do
  def_module("Records") do
    t1 = RECORD([:a, :b, :c], [INT, STRING, FLOAT])
    fun "test_record", t1 => t1
  end
end

require 'rocaml_extconf'

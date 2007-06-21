
# extension name, XXX in   require 'XXX'
EXT_NAME = "ocaml_tests"

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# some cmxa; auto-detection?
CAML_LIBS = %w[]

# list of .cmx (autodetected if empty)
CAML_OBJS = %w[]

# compilation flags
CAML_FLAGS = ""

# -I options (-I must be prepended) e.g. ["-I ../lib"]
CAML_INCLUDES = []

$:.unshift ".."

require 'rocaml'

def type(name)
  self.class.const_get(name.to_s.upcase)
end

Interface.generate("rocaml_tests") do
  def_module("Conversions") do
    %w[bool int float string unit].each do |name|
      fun name, type(name) => type(name)
      fun "#{name}_array", ARRAY(type(name)) => STRING
    end
    fun "int_array_array", ARRAY(ARRAY(INT)) => STRING
    fun "float_array_array", ARRAY(ARRAY(FLOAT)) => STRING
  end
end

require 'rocaml_extconf'

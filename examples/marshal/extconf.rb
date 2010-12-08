## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

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
  marshallers = {
    "vector_array" => ARRAY(vector_t),
    "string_array" => ARRAY(STRING),
    "int_array"    => ARRAY(INT),
  }

  def_class("FastMarshal") do |c|
    marshallers.each do |name, type|
      fun "dump", type => STRING, :aliased_as => "dump_#{name}"
      fun "load", STRING => type, :aliased_as => "load_#{name}"
    end
  end
end

require 'rocaml_extconf'
create_makefile(EXT_NAME)

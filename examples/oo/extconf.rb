
# extension name, XXX in   require 'XXX'
EXT_NAME = "oo"

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

Interface.generate("oo") do
  def_class("Oo") do |c|
    fun "new_from_string", STRING => c.abstract_type
    fun "new", INT => c.abstract_type
    method "inc", c.abstract_type => UNIT
    method "dec", c.abstract_type => UNIT
    method "get", c.abstract_type => INT
  end
end

require 'rocaml_extconf'
create_makefile(EXT_NAME)

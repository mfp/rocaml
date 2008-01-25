
# extension name, XXX in   require 'XXX'
EXT_NAME = "rocaml_tests"

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

MAPPING = {
  "big_int" => Types::Exported::BIGINT,
}

def type(name)
  self.class.const_get(name.to_s.upcase) rescue MAPPING[name]
end

Interface.generate("rocaml_tests") do
  def_module("Conversions") do
    %w[bool int big_int float string unit].each do |name|
      fun name, type(name) => type(name)
      fun "#{name}_array", ARRAY(type(name)) => STRING
      fun "#{name}_list", LIST(type(name)) => STRING
    end
    fun "int_array_array", ARRAY(ARRAY(INT)) => STRING
    fun "float_array_array", ARRAY(ARRAY(FLOAT)) => STRING
    fun "int_list_list", LIST(LIST(INT)) => STRING
    fun "float_list_list", LIST(LIST(FLOAT)) => STRING

    fun "int_tuple2", TUPLE(INT, INT) => STRING
    fun "float_tuple2", TUPLE(FLOAT, FLOAT) => STRING
    fun "int_float_tuple2", TUPLE(INT, FLOAT) => STRING
    fun "string_tuple2", TUPLE(STRING, STRING) => STRING
    fun "string_int_float_bool_tuple4",
      TUPLE(STRING, INT, FLOAT, BOOL) =>
        TUPLE(STRING, INT, FLOAT, BOOL)
  end

  def_class("T1", :under => "Conversions") do |c|
    t = c.abstract_type
    fun "make_t1", UNIT => t, :as => "new"
    method "binary_abstract_t1_t1", [t, t] => t, :as => "f"
  end

  def_class("T2", :under => "Conversions") do |c|
    t = c.abstract_type
    fun "make_t2", UNIT => t, :as => "new"
    method "binary_abstract_t2_t2", [t, t] => t, :as => "f"
  end
end

require 'rocaml_extconf'

create_makefile(EXT_NAME)

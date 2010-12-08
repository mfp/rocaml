## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

# extension name, XXX in   require 'XXX'
EXT_NAME = "fib"

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

$:.unshift "../.."

require 'rocaml'

Interface.generate("fib") do
  def_module("Fib") do
    fun "fib", INT => INT
    fun "fib_range", [INT, INT] => ARRAY(INT)
    fun "fib_range_s", [INT, INT] => ARRAY(STRING)
    fun "fib_range_plus", [INT, INT, ARRAY(FLOAT)] => ARRAY(FLOAT)
  end

  def_module("Conversions") do
    fun "sum_int_array", ARRAY(INT) => INT
    fun "sum_vectors",
      [TUPLE(FLOAT, FLOAT, FLOAT), TUPLE(FLOAT, FLOAT, FLOAT)] => TUPLE(FLOAT, FLOAT, FLOAT)
    fun "sum_arrays", [ARRAY(FLOAT), ARRAY(FLOAT)] => ARRAY(FLOAT)
    fun "raise_if_negative", INT => UNIT
  end
end

require 'rocaml_extconf'
create_makefile(EXT_NAME)

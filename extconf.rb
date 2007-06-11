
# Sample rocaml extconf.rb.
# Copy to your extension directory and modify as needed. In general, only
# EXT_NAME needs to be changed (in addition to the generated interface of
# course).

# extension name, XXX in  require 'XXX'
EXT_NAME = "foo"

# list of .cmx files to be linked, inferred from available .ml if empty
CAML_OBJS = %w[]

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# -I options (-I must be prepended)
CAML_INCLUDES = %w[]

# cmxa libraries to use
CAML_LIBS = %[]

# compilation flags
CAML_FLAGS = ""

require 'rocaml'

Interface.generate(EXT_NAME) do
  def_module("Foo", :under => "Some::NameSpace") do
    # Some::NameSpace::Foo.foo corresponding to  foo : int -> int
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
    # ACME::Bar.bar
    fun "bar", INT => INT
    # ACME::Bar.create, takes int, return ACME::Bar instance
    fun "create", INT => c.abstract_type
    # ACME::Bar#foo instance method
    method "foo", c.abstract_type => INT
    # ACME::Bar#bar instance method, taking an integer argument.
    #  o = ACME::Bar.create 42
    #  o.bar 1
    method "bar", [c.abstract_type, INT] => INT
  end
end

require 'rocaml_extconf'

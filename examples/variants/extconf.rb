
# extension name, XXX in   require 'XXX'
EXT_NAME = "variants"

# if non-empty, will use ocamlfind
OCAML_PACKAGES = %w[]

# cmxa
CAML_LIBS = %w[]

# list of .cmx (autodetected if empty)
CAML_OBJS = %w[]

# compilation flags
CAML_FLAGS = ""

# -I options (-I must be prepended)
CAML_INCLUDES = %w[]

$:.unshift "../.."

require 'rocaml'

Interface.generate("variants") do |iface|
  type = variant("kind") do
    constant :Foo
    constant :Bar
    constant :Baz
  end

  def_class("DummyBase", :under => "Variants") do |c|
    fun "create", UNIT => c.abstract_type, :aliased_as => "new"

    method "set_kind", [c.abstract_type, iface.type("kind")] => UNIT,
           :aliased_as => "kind="
    method "get_kind", c.abstract_type => iface.type("kind"),
           :aliased_as => "kind"
  end
end

require 'rocaml_extconf'

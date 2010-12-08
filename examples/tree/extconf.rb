## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

# extension name, XXX in   require 'XXX'
EXT_NAME = "tree"

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

Interface.generate("tree") do |iface|
  color = sym_variant("color"){ constant :R; constant :B }

  types = {}
  {:string => STRING, :int => INT}.each do |name, type|
    types["#{name}_tree"] = sym_variant("#{name}_tree") do |t|
      constant :Empty
      non_constant :Node, TUPLE(t, type, t)
    end

    types["#{name}_rbtree"] = sym_variant("#{name}_rbtree") do |t|
      constant :Empty
      non_constant :Node, TUPLE(color, t, type, t)
    end
  end

  [["Set", "tree"], ["RBSet", "rbtree"]].each do |implementation, tree_name|
    [["int", INT], ["string", STRING]].each do |typename, type|
      name = "#{typename.capitalize}#{implementation}"
      tree_type = types["#{typename}_#{tree_name}"]

      def_class(name) do |c|
        t = c.abstract_type
        fun "empty", UNIT => t, :aliased_as => "new"
        fun "make", tree_type => t

        method "add", [t, type] => t
        method "mem", [t, type] => BOOL, :aliased_as => "include?"
        method "dump", t => tree_type
        method "iter", t => t, :aliased_as => "each", :yield => [type, UNIT]
      end
    end
  end
end

require 'rocaml_extconf'
create_makefile(EXT_NAME)

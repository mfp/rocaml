## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

require 'mkmf'

%w[EXT_NAME OCAML_PACKAGES CAML_LIBS CAML_OBJS
   CAML_FLAGS CAML_INCLUDES].each do |c|
     begin
       c = Object.const_get(c)
     rescue Exception
       puts "You must define the #{c} constant"
       exit(1)
     end
   end

#EXT_NAME = "foo"          # extension name, XXX in   require 'XXX'
#OCAML_PACKAGES = %w[]     # if non-empty, will use ocamlfind
#CAML_LIBS = %w[]          # some cmxa
#CAML_OBJS = %w[]          # list of .cmx, autodetected if empty
#CAML_FLAGS = ""           # compilation flags
#CAML_INCLUDES = []        # -I options (-I must be prepended)


CAML_TARGET = "#{EXT_NAME}_rocaml_runtime.o"
if CAML_OBJS.empty?
  objects = Dir["*.ml"].map{|s| s.sub(/\.ml$/, ".cmx")}.reject do |f|
    f =~ /pa_.*/
  end
  CAML_OBJS.replace(objects)
end

ocaml_native_lib_path = %w[
  /usr/lib/ocaml/**/libasmrun.a
  /usr/local/lib/ocaml/**/libasmrun.a
].map{|glob| Dir[glob]}.flatten.sort.map{|x| File.dirname(x)}.last

if ocaml_native_lib_path.nil?
  puts "Couldn't find OCaml's native code runtime libasmrun.a"
  exit
end

$INCFLAGS << " -I#{ocaml_native_lib_path}"

maybe_opt = lambda{|x| opt = "#{x}.opt"; system(opt) ? opt : x }

if OCAML_PACKAGES.empty? then
  OCAMLC   = maybe_opt["ocamlc"]
  OCAMLOPT = maybe_opt["ocamlopt"]
  OCAMLDEP = maybe_opt["ocamldep"]
else
  cmd = lambda{|x| "ocamlfind #{x} -package #{OCAML_PACKAGES.join(",")}"}
  OCAMLC   = cmd["ocamlc"]
  OCAMLOPT = cmd["ocamlopt"]
  OCAMLDEP = cmd["ocamldep"]
end

def ocamlopt_ld_cmd(obj, *sources)
  linkpkg = OCAML_PACKAGES.empty? ? "" : "-linkpkg"
  "#{OCAMLOPT} $(OCAML_INCLUDES) -output-obj -o #{obj} $(OCAML_LIBS) #{sources.join(" ")} #{linkpkg}"
end

CAML_OBJS.push("rubyOCamlUtil.cmx") unless CAML_OBJS.include?("rubyOCamlUtil.cmx")
File.open("rubyOCamlUtil.ml", "w") do |f|
  f.puts <<EOF
(* register ocaml functions needed by ruby-ocaml *)
let _ =
  let r = Callback.register in
    (* used when mapping OCaml exceptions to Ruby *)
    r "Printexc.to_string" Printexc.to_string;
    r "Array.to_list" Array.to_list;
    r "Array.of_list" Array.of_list;
    r "Big_int.big_int_of_string" Big_int.big_int_of_string;
    r "Big_int.string_of_big_int" Big_int.string_of_big_int;
    ()

EOF
end

# required by the BIGINT conversions methods
CAML_LIBS << "nums.cmxa" unless CAML_LIBS.include?("nums.cmxa")

extra_caml_libs = (["unix.cmxa"] + CAML_LIBS).map do |x|
  File.join(ocaml_native_lib_path, "lib#{x.gsub(/cmxa$/,"a")}")
end.select{|x| File.exist?(x)}

# needed by mkmf's create_makefile
$LOCAL_LIBS = "#{ocaml_native_lib_path}/libasmrun.a #{extra_caml_libs.join(" ")}"
# try to add GCC's libgcc, required on Sparc
libgcc = Dir["/lib/libgcc*"].first
$LOCAL_LIBS << " " << libgcc if libgcc


unless OCAML_PACKAGES.empty?
  pkgdirs = `ocamlfind -query -r -format "%p %d" #{OCAML_PACKAGES.join(" ")}`.
            split(/\n/).map do |line|
              pkg, dir = line.split(/\s+/)
              if %w[nums unix].include?(pkg)
                nil
              else
                dir
              end
            end.compact
  local_libs = Dir["{#{pkgdirs.join(",")}}/lib*.a"].join(" ")
  puts "Will link against these package libs: #{local_libs}"
  $LOCAL_LIBS << " #{local_libs}"
end

# determine whether camlp4 (or camlp5) can be used:

have_camlp5 = ! `camlp5 -v 2>&1`["version"].nil?
camlp4version = `camlp4 -v 2>&1`[/version\s+(\d.*)/, 1]
have_camlp4 = ! camlp4version.nil?

pa_rocaml_revdeps = Dir["*.ml"].map do |f|
  "#{f.sub(/\.ml$/, ".cmx")}: pa_rocaml.cmo"
end.join("\n")

camlp4_flavor = nil

if have_camlp5
  CAML_FLAGS << " -pp 'camlp5o -I . pa_rocaml.cmo'"
  PA_ROCAML_RULES = <<-EOF
pa_rocaml.cmo: pa_rocaml.ml
	ocamlc -c -I +camlp5 -pp "camlp5o -I +camlp5 pa_extend.cmo q_MLast.cmo -loc _loc" pa_rocaml.ml

#{pa_rocaml_revdeps}
  EOF
  camlp4_flavor = 309

elsif have_camlp4 && camlp4version < "3.10.0"
  CAML_FLAGS << " -pp 'camlp4o -I . pa_rocaml.cmo'"
  PA_ROCAML_RULES = <<-EOF
pa_rocaml.cmo: pa_rocaml.ml
	ocamlc -c -I +camlp4 -pp "camlp4o -I +camlp4 pa_extend.cmo q_MLast.cmo -loc _loc" pa_rocaml.ml

#{pa_rocaml_revdeps}
  EOF
  camlp4_flavor = 309

elsif have_camlp4 && camlp4version >= "3.10.0"
  CAML_FLAGS << " -pp 'camlp4o -I . pa_rocaml.cmo'"
  PA_ROCAML_RULES = <<-EOF
pa_rocaml.cmo: pa_rocaml.ml
	ocamlc -c -I +camlp4 -pp "camlp4orf -loc _loc" pa_rocaml.ml

#{pa_rocaml_revdeps}
  EOF
  camlp4_flavor = 310

elsif defined? NEED_CAMLP4 && NEED_CAMLP4
  puts <<-EOF
This extension needs the camlp4 (or alternatively camlp5) Pre-Processor
and Pretty Printer for OCaml, probably to be found in the camlp4 or camlp5
packages. camlp4 is distributed with OCaml and will be installed if you
build the interpreter from the sources.

Run extconf.rb again once you've installed it.
  EOF
  exit(1)

else # not found, but not actually said to be needed either, assume it's OK
  PA_ROCAML_RULES = ""
end

if File.exist?("depend.in")
  File.open("depend", "w"){|f| f.print File.read("depend.in") }
else
  File.open("depend", "w"){|f| } # overwrite previous
end

ocamldep_sources = (Dir["*.ml"] + Dir["*.mli"]) - %w[pa_rocaml.ml]

File.open("depend", "a") do |f|
  f.puts <<EOF


#############################################################################
#                                                                           #
#                               Objective Caml                              #
#                                                                           #
#############################################################################

OCAMLC   = #{OCAMLC}
OCAMLOPT = #{OCAMLOPT}
OCAMLDEP = #{OCAMLDEP}
OFLAGS   = #{CAML_FLAGS}
OCAML_INCLUDES = #{CAML_INCLUDES.join(" ")}
OCAML_LIBS     = #{CAML_LIBS.join(" ")}

OCAML_TARGET = #{CAML_TARGET}

$(DLLIB): $(OCAML_TARGET)

$(OCAML_TARGET): #{CAML_OBJS.join(" ")} #{CAML_OBJS.map{|x| x.sub(/\.cmx$/, ".o")}.join(" ")}
	#{ocamlopt_ld_cmd("$@", "$^")}

#{PA_ROCAML_RULES}

.SUFFIXES: .c .m .cc .cxx .cpp .C .o .mli .ml .cmi .cmo .cmx

.mli.cmi:
	$(OCAMLC) -c $(BFLAGS) $(OCAML_INCLUDES) $<

.ml.cmo:
	$(OCAMLC) -c $(BFLAGS) $(OCAML_INCLUDES) $<

.ml.o:
	$(OCAMLOPT) -c $(OFLAGS) $(OCAML_INCLUDES) $<

.ml.cmx:
	$(OCAMLOPT) -c $(OFLAGS) $(OCAML_INCLUDES) $<

# clean

.PHONY: clean_rocaml

clean_rocaml:
	@-$(RM) *.cmx *.cmi *.cmo

clean: clean_rocaml

.PHONY: distclean_rocaml

distclean_rocaml:
	@-$(RM) *_rocaml_wrapper.c depend .depend rubyOCamlUtil.ml pa_rocaml.ml

distclean: distclean_rocaml

# depend
########

.depend depend:
	@-$(RM) .depend
	$(OCAMLDEP) $(OCAML_INCLUDES) #{ocamldep_sources.map{|x| x.intern}.join(" ")} > .depend

include .depend
EOF
end

PA_ROCAML_309 = <<'EOF'

let module_name =
  let s = Sys.argv.(Array.length Sys.argv - 1) in
    String.capitalize (String.sub s 0 (String.rindex s '.'))
let namespace = ref module_name

let export _loc ids =
  let exprs = List.map
                (fun id ->
                   let name = !namespace ^ "." ^ id in
                     <:expr< Callback.register $str:name$ $lid:id$ >>)
                ids in
  <:str_item< do { $list:exprs$ } >>


EXTEND
  Pcaml.str_item: LEVEL "top" [
    [
      "export"; names = LIST1 LIDENT SEP "," -> export _loc names
    | "export"; e = Pcaml.expr; "aliased"; id = Pcaml.expr ->
        let id = <:expr< $str:!namespace$ ^ "." ^ $id$ >> in
          <:str_item< do{ Callback.register $id$ $e$ } >>
    | "namespace"; n = STRING -> namespace := n; <:str_item< declare end >>
    ]
  ];
END;;
EOF

PA_ROCAML_310 = <<'EOF'

open Camlp4.PreCast

let module_name =
  let s = Sys.argv.(Array.length Sys.argv - 1) in
    String.capitalize (String.sub s 0 (String.rindex s '.'))
let namespace = ref module_name

let export _loc ids =
  let exprs = List.map
                (fun id ->
                   let name = !namespace ^ "." ^ id in
                     <:expr< Callback.register $str:name$ $lid:id$ >>)
                ids in
  <:str_item< do { $list:exprs$ } >>


EXTEND Gram
  Syntax.str_item: LEVEL "top" [
    [
      "export"; names = LIST1 [ x = LIDENT -> x ] SEP "," -> export _loc names
    | "export"; e = Syntax.expr; "aliased"; id = Syntax.expr ->
        let id = <:expr< $str:!namespace$ ^ "." ^ $id$ >> in
          <:str_item< do{ Callback.register $id$ $e$ } >>
    | "namespace"; n = STRING -> namespace := n; <:str_item< >>
    ]
  ];
END;;
EOF

case camlp4_flavor
when 309
  File.open("pa_rocaml.ml", "w"){|f| f.puts PA_ROCAML_309}
when 310
  File.open("pa_rocaml.ml", "w"){|f| f.puts PA_ROCAML_310}
end

class Object
  old_create_makefile = instance_method(:create_makefile)
  define_method(:create_makefile) do |target|
    $LOCAL_LIBS = "#{CAML_TARGET} #{$LOCAL_LIBS}"
    old_create_makefile.bind(self).call(target)
  end
end

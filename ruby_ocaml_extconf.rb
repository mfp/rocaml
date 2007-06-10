require 'mkmf'

%w[EXT_NAME OCAML_PACKAGES CAML_LIBS CAML_OBJS CAML_TARGET
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
#CAML_LIBS = %[]           # some cmxa; auto-detection?
#CAML_OBJS = %w[]          # list of .cmx
#CAML_TARGET = %w[]        # a .o file that will contain your code and the runtime
#CAML_FLAGS = ""           # compilation flags
#CAML_INCLUDES = %w[]      # -I options (-I must be prepended)

ocaml_native_lib_path = %w[
  /usr/lib/ocaml/**/libasmrun.a
  /usr/local/lib/ocaml/**/libasmrun.a
].map{|glob| Dir[glob]}.flatten.sort.last

if ocaml_native_lib_path.nil?
  puts "Couldn't find OCaml's native code runtime libasmrun.a"
  exit
end

maybe_opt = lambda{|x| opt = "#{x}.opt"; system(x) ? opt : x }

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
  "#{OCAMLOPT} -output-obj -o #{obj} #{sources.join(" ")}"
end

$LOCAL_LIBS = "#{CAML_TARGET} #{ocaml_native_lib_path}"

create_makefile(EXT_NAME)

File.open("Makefile", "a") do |f|
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

OCAML_TARGET = #{CAML_TARGET}

$(DLLIB): $(OCAML_TARGET)

$(OCAML_TARGET): #{CAML_OBJS.join(" ")} #{CAML_OBJS.map{|x| x.sub(/\.cmx$/, ".o")}.join(" ")}
	#{ocamlopt_ld_cmd("$@", "$?")}


.SUFFIXES: .c .m .cc .cxx .cpp .C .o .mli .ml .cmi .cmo .cmx

.mli.cmi:
	$(OCAMLC) -c $(BFLAGS) $<

.ml.cmo:
	$(OCAMLC) -c $(BFLAGS) $<

.ml.o:
	$(OCAMLOPT) -c $(OFLAGS) $<

.ml.cmx:
	$(OCAMLOPT) -c $(OFLAGS) $<

# clean

.PHONY: clean_ocaml

clean_ocaml:
	@-$(RM) *.cmx *.cmi *.cmo

clean: clean_ocaml

# depend
########

.depend depend:
	rm -f .depend
	$(OCAMLDEP) $(OCAML_INCLUDES) *.ml *.mli > .depend

include .depend
EOF
end


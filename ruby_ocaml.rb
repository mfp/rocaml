
module Types
  class Type
    def name; self.class.name.split(/::/).last end
    def need_helper?
      false
    end
  end

  class Unit < Type
    def caml_to_ruby(x); "Qnil" end
    def ruby_to_caml(x); "Val_unit" end
  end

  class Int < Type
    def caml_to_ruby(x); "INT2NUM(Int_val(#{x}))" end
    def ruby_to_caml(x); "Val_int(NUM2INT(#{x}))" end
  end

  class String < Type
    def caml_to_ruby(x)
      "rb_str_new2(String_val(#{x}))"
    end

    def ruby_to_caml(x)
      # TODO: use StringValueCStr ?? involves extra strlen
      "caml_copy_string(StringValuePtr(#{x}))"
    end
  end

  class Bool < Type
    def caml_to_ruby(x)
      "#{x} == Val_false ? Qfalse : Qtrue"
    end

    def ruby_to_caml(x)
      "RTEST(#{x}) ? Val_true : Val_false"
    end
  end

  class Array < Type
    def initialize(el_type)
      @type = el_type
      @c_to_r_helper = "#{@type.name.gsub(/\s+/, "")}_array_caml_to_ruby"
      @r_to_c_helper = "#{@type.name.gsub(/\s+/, "")}_array_ruby_to_caml"
    end

    def need_helper?
      true
    end

    def name; "#{@type.name.gsub(/\s+/, "")} array" end

    def caml_to_ruby(x)
      "#{@c_to_r_helper}(#{x})"
    end

    def ruby_to_caml(x)
      "#{@r_to_c_helper}(#{x})"
    end

    def caml_to_ruby_helper
      <<EOF
static VALUE
#{@c_to_r_helper}(value v)
{
  CAMLparam1(v);
  VALUE ret;
  int siz;
  int i;

  siz = Wosize_val(v) - 1;
  ret = rb_ary_new2(siz);
  for(i = 0; i < siz; i++) {
      RARRAY(ret)->ptr[i] = #{@type.caml_to_ruby("Field(v, i)")};
  }
  RARRAY(ret)->len = siz;

  return ret;
}


EOF
    end

    def ruby_to_caml_helper
      <<EOF
static value
#{@r_to_c_helper}(VALUE v)
{
  CAMLparam0();
  CAMLlocal1(ret);
  int siz;
  int i;

  siz = RARRAY(v)->len;
  ret = caml_alloc(siz, 0);
  for(i = 0; i < siz; i++) {
      Store_field(ret, i, #{@type.ruby_to_caml("RARRAY(v)->ptr[i]")});
  }

  CAMLreturn(ret);
}


EOF
    end
  end # Array

  module Exported
    INT = Int.new
    BOOL = Bool.new
    STRING = String.new
    UNIT = Unit.new
    def ARRAY(type); Array.new(type) end
  end
end

include Types::Exported

class Mapping 
  attr_reader :src, :dst, :name

  # self_type: if set, pass self as abstract type taken from opaque RDATA
  # object
  def initialize(name, src_type, dst_type, self_type)
    @name = name
    @src = src_type
    @dst = dst_type
    @self_type = self_type
  end

  def mangled_name(prefix = "")
    prefix + mangle_caml_name(@name)
  end

  def generate(prefix = "")
    <<EOF
VALUE #{mangled_name(prefix)}
      (VALUE self#{param_list.empty? ? "" : ", "}#{param_list.map{|x| "VALUE #{x}"}.join(", ")})
{
#{locals(["ret"] + caml_param_list).join("\n")}
#{"  value args[32];" if arity > 3}
  static value *closure = NULL;
  if(closure == NULL) {
    closure = caml_named_value("#{@name}");
    if(closure == NULL) {
      rb_raise(rb_eStandardError, "Couldn't find OCaml value #{@name}.");
    }
  }

#{prepare_callback("args")}
  ret = #{callback("*closure", "args")};
  if(Is_exception_result(ret)) {
    raise_ocaml_exception(Extract_exception(ret));
  }
  return #{dst.caml_to_ruby("ret")};
}


EOF
  end

  def arity
    case @src
    when Array; @src.size
    when UNIT; 0
    else 1
    end
  end

  private
  def callback(f, args)
    case ar = arity
    when 0; "caml_callback_exn(#{f}, Val_unit)"
    when 1; "caml_callback_exn(#{f}, param1)"
    when 2, 3; 
      "caml_callback#{arity}_exn(#{f}, #{param_list.join(", ")})"
    else
      "  caml_callbackN_exn(#{f}, #{arity}, #{args})"
    end
  end

  def prepare_callback(args)
    case arity
    when 1
      "  #{caml_param_list.first} = " + @src.ruby_to_caml(param_list.first) + ";"
    when 2, 3
      i = 1
      caml_param_list.zip(param_list).map do |caml, ruby|
        r = "  #{caml} = " + @src[i-1].ruby_to_caml(ruby) + ";"
        i += 1
        r
      end
    else
      i = 1
      param_list.map do |p|
        r = "  #{args}[#{i-1}] = " + @src[i-1].ruby_to_caml(p) + ";"
        i += 1
        r
      end.join("\n")
    end
  end

  def def_aux(name, params, acc = [])
    return acc if params.empty?
    5.downto(1) do |i|
      if params.size >= i then
        return locals(params[i..-1], 
                      acc + ["  #{name}#{i}(" + params[0, i].join(", ") + ");"])
      end
    end
    acc # shouldn't happen
  end

  def locals(vars, acc = [])
    def_aux("CAMLlocal", vars, acc)
  end

  def params(params, acc = [])
    def_aux("CAMLparam", params, acc)
  end

  def caml_param_list
    (1..arity).map{|i| "caml_param#{i}"}
  end

  def param_list
    (1..arity).map{|i| "param#{i}"}
  end

  def mangle_caml_name(name)
    "wrapper__" + name.gsub(/\./, "_")
  end
end

class Interface
  class Context
    attr_reader :name

    def initialize(name, options = {})
      @name = name
      @mappings = []
    end

    def fun(name, types_and_options)
      types_and_options = types_and_options.clone
      raise "Want a type => type mapping" unless Hash === types_and_options
      self_type = types_and_options.delete(:self)
      from = types_and_options.keys.first
      to   = types_and_options[from]
      @mappings << Mapping.new(name, from, to, self_type)
    end

    def container_name
      raise "Must be redefined"
    end

    def emit_container_definition(io)
      raise "Must be redefined"
    end

    def emit_method_definitions
      raise "Must be redefined"
    end

    def emit_container_declaration(io)
      io.puts "VALUE #{container_name};"
    end

    def emit_helpers(io, emitted_helpers)
      @mappings.each do |m|
        emit_helper_aux(io, m.src, emitted_helpers, :ruby_to_caml)
        emit_helper_aux(io, m.dst, emitted_helpers, :caml_to_ruby)
      end
    end

    def emit_wrappers(io)
      @mappings.each{|m| io.puts m.generate(@name)}
    end

    def emit_helper_aux(io, type, emitted, direction)
      case type
      when Array
        type.each{|x| emit_helper_aux(io, x, emitted, direction)}
      else
        if type.need_helper? && !emitted[[direction, type.name]]
          emitted[[direction, type.name]] = true
          case direction
          when :caml_to_ruby
            io.puts type.caml_to_ruby_helper
          else
            io.puts type.ruby_to_caml_helper
          end
          io.puts
        end
      end
    end
  end

  class Class < Context
    DEFAULT_OPTIONS = {
      :super => "rb_cObject",
      :under => nil
    }
    def initialize(name, options = {})
      options = DEFAULT_OPTIONS.merge(options)
      super(name)
      @superclass = options[:super]
      @scope      = options[:under]
    end

    def container_name
      "c#{@name}"
    end

    def emit_container_definition(io)
      if @scope
        io.puts <<EOF  
  {
    VALUE scope;
    scope = rb_eval_string("#{@scope}");
    #{container_name} = rb_define_class_under(scope, "#{@name}", #{@superclass});
  }
EOF
      else
        io.puts %[  #{container_name} = rb_define_class("#{@name}", #{@superclass});]
      end
    end

    def emit_method_definitions(io)
      @mappings.each do |m|
        io.puts %[  rb_define_method(#{container_name}, "#{m.name}", #{m.mangled_name(@name)}, #{m.arity});]
      end
    end
  end

  class Module < Context
    DEFAULT_OPTIONS = {
      :under => nil,
    }
    def initialize(name, options = {})
      options = DEFAULT_OPTIONS.merge(options)
      super(name)
      @scope = options[:under]
    end

    def container_name
      "m#{@name}"
    end

    def emit_container_definition(io)
      if @scope
        io.puts <<EOF
  {
    VALUE scope = rb_eval_string("#{@scope}");
    #{container_name} = rb_define_module_under(scope, "#{@name}");
  }
EOF
      else
        io.puts %[  #{container_name} = rb_define_module("#{@name}");]
      end
    end

    def emit_method_definitions(io)
      @mappings.each do |m|
        io.puts %[  rb_define_singleton_method(#{container_name}, "#{m.name}", #{m.mangled_name(@name)}, #{m.arity});]
      end
    end
  end

  def self.define(*args, &block)
    ret = new(*args)
    ret.instance_eval(&block)
    ret
  end

  def self.generate(*args, &block)
    define(*args, &block).generate
  end

  DEFAULT_OPTIONS = {
    :dest => "ocaml_wrap.c",
    :class => nil,
  }

  def initialize(extname, options = {})
    options = DEFAULT_OPTIONS.merge(options)
    @contexts   = []
    @extname    = extname
    @dst_file   = options[:dest]
    @class_name = options[:class] || extname.capitalize
  end

  def def_module(name, options = {}, &block)
    c = Module.new(name, options)
    c.instance_eval(&block)
    @contexts << c
  end

  def def_class(name, options = {}, &block)
    c = Class.new(name, options)
    c.instance_eval(&block)
    @contexts << c
  end

  def generate
    File.open(@dst_file, "w") do |f|
      f.puts <<EOF
#include "ruby.h"
#include <string.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>

EOF
      @contexts.each{|c| c.emit_container_declaration(f)}
      f.puts <<EOF

static void raise_ocaml_exception(value exn)
{
  static value *closure;
  value str;

  if(closure == NULL) {
    closure = caml_named_value("Printexc.to_string");
  }
  str = caml_callback(*closure, exn);
  rb_raise(rb_eStandardError, "OCaml exception: %s", String_val(str));

  /* never reached */
}

EOF
      emitted_helpers = {}
      @contexts.each{|c| c.emit_helpers(f, emitted_helpers)}
      @contexts.each{|c| c.emit_wrappers(f)}
      # TODO: handle args in argv (GC params, etc)
      # TODO: multiple classes, modules, under which scope
      f.puts <<EOF

char *argv[] = { NULL };

void Init_#{@extname}()
{

  caml_startup(argv);
EOF
      @contexts.each{|c| c.emit_container_definition(f)}
      @contexts.each{|c| c.emit_method_definitions(f)}
      f.puts "}"
    end
  end
end


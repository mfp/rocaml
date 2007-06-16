##
## rocaml Copyright (c) 2007 Mauricio Fernandez <mfp@acm.org>
##
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

class Object
  # instance_eval doesn't pass self to the block in 1.9 (might be fixed)
  def do_instance_eval(&block)
    if RUBY_VERSION >= "1.9.0"
      self.instance_exec(self, &block)
    else
      self.instance_eval(&block)
    end
  end
end


module CodeGeneratorHelper
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
end

module Types
  class Type
    def name; self.class.name.split(/::/).last end

    def ruby_to_caml_safe(x, status)
      ruby_to_caml(x)
    end

    def type_dependencies
      []
    end
  end

  class Unit < Type
    def caml_to_ruby(x); "Qnil" end
    def ruby_to_caml(x); "Val_unit" end
  end

  class Int < Type
    def caml_to_ruby(x); "INT2NUM(Int_val(#{x}))" end
    def ruby_to_caml(x); "Val_int(NUM2INT(#{x}))" end

    def ruby_to_caml_safe(x, status)
      "int_ruby_to_caml(#{x}, #{status})"
    end

    def ruby_to_caml_helper
      <<-EOF
static value
int_ruby_to_caml(VALUE v, int *status)
{
  CAMLparam0();
  int tmp;

  if(FIXNUM_P(v)) {
      CAMLreturn(Val_int(FIX2INT(v)));
  }

  /* need conversion */
  tmp = (int) rb_protect((VALUE (*)(VALUE))rb_num2long, v, status);
  /* if it fails, the caller will know through status */
  CAMLreturn(Val_long(tmp));
}

      EOF
    end
  end

  class String < Type
    def caml_to_ruby(x)
      "rb_str_new2(String_val(#{x}))"
    end

    def ruby_to_caml(x)
      # TODO: use StringValueCStr ?? involves extra strlen
      "caml_copy_string(StringValuePtr(#{x}))"
    end

    def ruby_to_caml_helper
      <<-EOF
static value
string_ruby_to_caml_safe(VALUE s, int *status)
{
  char *r;
  CAMLparam0();
  CAMLlocal1(ret);

  r = (char *)rb_protect((VALUE (*)(VALUE)) rb_string_value_ptr, (VALUE)&s, status);
  if(!*status) {
      ret = caml_copy_string(r);
  } else {
      ret = Val_false;
  }

  CAMLreturn(ret);
}

      EOF
    end

    def ruby_to_caml_safe(x, status)
      "string_ruby_to_caml_safe(#{x}, #{status})"
    end
  end

  class Bool < Type
    def caml_to_ruby(x)
      "Bool_val(#{x}) ? Qtrue : Qfalse"
    end

    def ruby_to_caml(x)
      "RTEST(#{x}) ? Val_true : Val_false"
    end
  end

  class Float < Type
    def caml_to_ruby(x)
      "rb_float_new(Double_val(#{x}))"
    end

    def ruby_to_caml(x)
      "caml_copy_double(RFLOAT(rb_Float(#{x}))->value)"
    end

    def ruby_to_caml_helper
      <<-EOF
static
value safe_rbFloat_to_caml(VALUE v, int *status)
{
  VALUE r;
  CAMLparam0();
  CAMLlocal1(ret);

  r = rb_protect(rb_Float, v, status);
  if(!*status) {
      ret = caml_copy_double(RFLOAT(r)->value);
  } else {
      ret = Val_false;
  }

  CAMLreturn(ret);
}
      EOF
    end

    def ruby_to_caml_safe(x, status)
      "safe_rbFloat_to_caml(#{x}, #{status})"
    end
  end

  class Array < Type
    def initialize(el_type)
      @type = el_type
      @c_to_r_helper = "#{@type.name.gsub(/\s+/, "")}_array_caml_to_ruby"
      @r_to_c_helper = "#{@type.name.gsub(/\s+/, "")}_array_ruby_to_caml"
    end

    def type_dependencies
      [@type]
    end

    def name; "#{@type.name.gsub(/\s+/, "")} array" end

    def caml_to_ruby(x)
      "#{@c_to_r_helper}(#{x})"
    end

    def ruby_to_caml(x)
      "#{@r_to_c_helper}(#{x})"
    end

    def caml_to_ruby_helper
      if Float === @type
        <<-EOF
static VALUE
#{@c_to_r_helper}(value v)
{
  CAMLparam1(v);
  VALUE ret;
  int siz;
  int i;

  siz = Wosize_val(v) / 2; /* 2 words per double; (size - 1) / 2 is wrong */
  ret = rb_ary_new2(siz);
  for(i = 0; i < siz; i++) {
      RARRAY(ret)->ptr[i] = rb_float_new(Double_field(v, i));
  }
  RARRAY(ret)->len = siz;

  CAMLreturn(ret);
}

        EOF
      else
        <<-EOF
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

  CAMLreturn(ret);
}

        EOF
      end
    end

    def ruby_to_caml_helper
      if Float === @type
        <<-EOF
static value
#{@r_to_c_helper}(VALUE v)
{
  CAMLparam0();
  CAMLlocal1(ret);
  int siz;
  int i;

  siz = RARRAY(v)->len;
  ret = caml_alloc(siz * 2, Double_array_tag); /* 2 words per double */
  for(i = 0; i < siz; i++) {
      Store_double_field(ret, i, RFLOAT(rb_Float(RARRAY(v)->ptr[i]))->value);
  }

  CAMLreturn(ret);
}

static value
#{@r_to_c_helper}_safe(VALUE v, int *status)
{
  int siz;
  int i;
  CAMLparam0();
  CAMLlocal2(ret, camlv);

  siz = RARRAY(v)->len;
  ret = caml_alloc(siz * 2, Double_array_tag); /* 2 words per double */
  for(i = 0; i < siz; i++) {
      int s = 0;

      camlv = #{@type.ruby_to_caml_safe("RARRAY(v)->ptr[i]", "&s")};
      if(s) {
        *status = s;
        CAMLreturn(Val_false);
      }
      Store_double_field(ret, i, camlv);
  }

  CAMLreturn(ret);
}
        EOF
      else
        <<-EOF
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

static value
#{@r_to_c_helper}_safe(VALUE v, int *status)
{
  CAMLparam0();
  CAMLlocal2(ret, camlv);
  int siz;
  int i;

  siz = RARRAY(v)->len;
  ret = caml_alloc(siz, 0);
  for(i = 0; i < siz; i++) {
      int s = 0;

      camlv = #{@type.ruby_to_caml_safe("RARRAY(v)->ptr[i]", "&s")};
      if(s) {
        *status = s;
        CAMLreturn(Val_false);
      }
      Store_field(ret, i, camlv);
  }

  CAMLreturn(ret);
}

        EOF
      end
    end
  end # Array

  class Abstract < Type
    attr_reader :name
    def initialize(name)
      @name = name
    end

    def caml_to_ruby(x)
      "wrap_abstract_#{name}(#{x})"
    end

    def ruby_to_caml(x)
      "unwrap_abstract_#{name}(#{x})"
    end

    def caml_to_ruby_helper
      <<EOF
static void
abstract_#{name}_free(abstract_#{name} *ptr)
{
  if(ptr) {
    caml_remove_global_root(&ptr->v);
    free(ptr);
  }
}

static VALUE
wrap_abstract_#{name}(value v)
{
  CAMLparam1(v);
  abstract_#{name} *ptr;
  VALUE ret;

  ret = Data_Make_Struct(#{name}, abstract_#{name}, 0, abstract_#{name}_free, ptr);
  caml_register_global_root(&ptr->v);
  ptr->v = v;
  CAMLreturn(ret);
}


EOF
    end

    def ruby_to_caml_helper
      # ruby_to_caml will be called before, must contain type definition
      <<EOF
typedef struct {
  value v;
} abstract_#{name};

static value
unwrap_abstract_#{name}(VALUE v)
{
  CAMLparam0();
  abstract_#{name} *ptr;

  Data_Get_Struct(v, abstract_#{name}, ptr);
  CAMLreturn(ptr->v);
}


EOF
    end
  end

  class Variant < Type
    attr_reader :name
    def initialize(name)
      @name = name
      @constant_constructors     = {}
      @non_constant_constructors = {}
      @types = []
    end

    def type_dependencies
      @types
    end

    def constant(name)
      raise "Repeated constant constructor #{name}" if @constant_constructors.has_key?(name)
      @constant_constructors[name] = @constant_constructors.size
    end

    def non_constant(name, type)
      raise "Repeated non-constant constructor #{name}" if @non_constant_constructors.has_key?(name)
      if Types::Tuple === type
        type = type.with_tag(@types.size)
      else
        type = Types::Tuple.new(type).with_tag(@types.size)
      end
      @non_constant_constructors[name] = [@types.size, type]
      @types << type
    end

    def constant_tag(name)
      @constant_constructors[name]
    end

    def non_constant_tag(name)
      @non_constant_constructors[name][0]
    end

    def non_constant_type(name)
      @non_constant_constructors[name][1]
    end

    def ruby_to_caml(x)
      "#{name}_ruby_to_caml(#{x}, NULL)"
    end

    def ruby_to_caml_safe(x, status)
      "#{name}_ruby_to_caml(#{x}, #{status})"
    end

    def caml_to_ruby(x)
      # TODO: non-constant constructors
      "#{name}_caml_to_ruby(#{x})"
    end

    def caml_to_ruby_helper
      non_constant_cases = (0...@types.size).map do |i|
        case @types[i].size
        when 1
          convert = "rb_ary_push(ret, RARRAY(#{@types[i].caml_to_ruby("v")})->ptr[0]);"
        else
          convert = "rb_ary_push(ret, #{@types[i].caml_to_ruby("v")});"
        end
        <<-EOF
  case #{i}:
    #{convert}
    CAMLreturn(ret);
        EOF
      end.join("\n")
      <<-EOF
static VALUE
#{name}_caml_to_ruby(value v)
{
  VALUE ret;
  CAMLparam1(v);

  if(Is_long(v)) {
    CAMLreturn(INT2FIX(Int_val(v)));
  }

  ret = rb_ary_new();
  rb_ary_push(ret, INT2FIX(Tag_val(v)));
  switch(Tag_val(v)) {
#{non_constant_cases}
    default:
      rb_warning("Unknown tag for type #{name}, returning nil. Check your OCaml interface definition");
      CAMLreturn(Qnil);
  }
}
      EOF
    end

    def ruby_to_caml_helper
      non_constant_tag_cases = (0...@types.size).map do |i|
        <<-EOF
  case #{i}:
    camlval = #{@types[i].ruby_to_caml_safe("RARRAY(tuple)->ptr[1]", "status")};
    if(status && *status) CAMLreturn(Val_false); /* normally redundant */
    CAMLreturn(camlval);
        EOF
      end.join("\n")

      <<-EOF
static VALUE
#{name}_do_raise(VALUE wrong_tag)
{
  rb_raise(rb_eRuntimeError, "Tag %d isn't defined for variant '#{name}'", FIX2INT(wrong_tag));
}

static value
#{name}_constant_ruby_to_caml(VALUE v, int *status)
{
  int tag;
  CAMLparam0();

  tag = (int) rb_protect((VALUE (*)(VALUE))rb_num2long, v, status);
  if(*status) CAMLreturn(Val_false);

  if(tag < 0 || tag >= #{@constant_constructors.size}) {
    rb_protect(#{name}_do_raise, tag, status);
    CAMLreturn(Val_false);
    /* this will signal the error through status; the caller must handle it */
  }
  CAMLreturn(Val_int(tag));
}

static value
#{name}_non_constant_ruby_to_caml(VALUE v, int *status)
{
  VALUE tuple;
  int tag;
  CAMLparam0();
  CAMLlocal1(camlval);

  tuple = rb_protect(rb_Array, v, status);
  if(status && *status) CAMLreturn(Val_false);
  if(RARRAY(tuple)->len != 2 || TYPE(RARRAY(tuple)->ptr[0]) != T_FIXNUM) {
    do_raise_exception_tag(rb_eRuntimeError,
                           "Non-constant constructor expects a 2-element array [TAG, VALUE]",
                           status);
    CAMLreturn(Val_false);
  }

  tag = FIX2INT(RARRAY(tuple)->ptr[0]);
  switch(tag) {
#{non_constant_tag_cases}
  default:
    rb_protect(#{name}_do_raise, tag, status);
    CAMLreturn(Val_false);
  }
}

static value
#{name}_ruby_to_caml(VALUE v, int *status)
{
 CAMLparam0();

 if(TYPE(v) == T_FIXNUM) {
   CAMLreturn(#{name}_constant_ruby_to_caml(v, status));
 }
 CAMLreturn(#{name}_non_constant_ruby_to_caml(v, status));
}

      EOF
    end
  end

  class Tuple < Type
    include CodeGeneratorHelper

    attr_reader :name
    def initialize(*types)
      if Numeric === types.last
        @tag = types.last
        types = types[0..-2]
        @name = (["t"] + types.map{|x| x.name} + ["tuple#{@tag}"]).join("_")
      else
        @tag = 0
        @name = (["t"] + types.map{|x| x.name} + ["tuple"]).join("_")
      end
      @types = types
    end

    def size
      @types.size
    end

    def with_tag(tag)
      self.class.new(*(@types + [tag]))
    end

    def type_dependencies
      @types
    end

    def ruby_to_caml_helper
      conversions = (0...@types.size).map do |idx|
        <<-EOF
  Store_field(ret, #{idx}, #{@types[idx].ruby_to_caml_safe("RARRAY(v)->ptr[#{idx}]", "status")});
  if(status && *status) CAMLreturn(Val_false);
        EOF
      end.join("\n")

      <<-EOF
static VALUE
#{name}_do_raise(char *s)
{
  rb_raise(rb_eRuntimeError, "%s", s);
}

static value
#{name}_ruby_to_caml(VALUE v, int *status)
{
  CAMLparam0();
  CAMLlocal1(ret);

  v = rb_protect(rb_Array, v, status);
  if(status && *status) CAMLreturn(Val_false);

  if(TYPE(v) != T_ARRAY || RARRAY(v)->len != #{@types.size}) {
    rb_protect((VALUE (*)(VALUE))#{name}_do_raise,
               (VALUE)"Conversion to OCaml with #{name} needs a #{@types.size}-element array",
               status);
    CAMLreturn(Val_false);
  }

  ret = caml_alloc(#{@types.size}, #{@tag});
#{conversions}
  CAMLreturn(ret);
}
      EOF
    end

    def caml_to_ruby_helper
      conversions = (0...@types.size).map do |i|
        %[  rb_ary_push(ret, #{@types[i].caml_to_ruby("Field(v, #{i})")});]
      end.join("\n")

      <<-EOF
static VALUE
#{name}_caml_to_ruby(value v)
{
  VALUE ret;
  CAMLparam1(v);

  ret = rb_ary_new();
#{conversions}
  CAMLreturn(ret);
}
      EOF
    end

    def caml_to_ruby(x)
      "#{name}_caml_to_ruby(#{x})"
    end

    def ruby_to_caml(x)
      "#{name}_ruby_to_caml(#{x}, NULL)"
    end

    def ruby_to_caml_safe(x, status)
      "#{name}_ruby_to_caml(#{x}, #{status})"
    end
  end

  module Exported
    INT = Int.new
    BOOL = Bool.new
    STRING = String.new
    UNIT = Unit.new
    FLOAT = Float.new
    def ARRAY(type); Array.new(type) end
    def ABSTRACT(name); Abstract.new(name) end
    def TUPLE(*types); Tuple.new(*types) end
  end
end

include Types::Exported

class Mapping
  include CodeGeneratorHelper
  attr_reader :src, :dst, :name, :pass_self

  DEFAULT_OPTIONS = {
    :safe => true,
    :aliased_as => nil
  }

  def initialize(name, src_type, dst_type, pass_self, options = {})
    options = DEFAULT_OPTIONS.merge(options)
    @name = options[:aliased_as] || name
    @caml_name = name
    @src = src_type
    @dst = dst_type
    @pass_self = pass_self
    @safe = options[:safe]
  end

  def mangled_name(prefix)
    prefix + "_wrapper__" + (@pass_self ? "" : "s_") + @caml_name.gsub(/\./, "_")
  end

  def generate(prefix)
    fmt = lambda{|a| a.map{|x| "VALUE #{x}"}.join(", ")}
    if @pass_self
      formal_args = param_list
    else
      formal_args = ["self"] + param_list
    end
    <<EOF
VALUE #{mangled_name(prefix)}_ex
      (VALUE *exception, int *status, #{fmt[formal_args]})
{
  CAMLparam0();
#{locals(["ret"] + caml_param_list).join("\n")}
#{"  value args[32];" if arity > 3}
  static value *closure = NULL;

  if(closure == NULL) {
    closure = caml_named_value("#{prefix}.#{@caml_name}");
    if(closure == NULL) {
      *exception = rb_str_new2("Couldn't find OCaml value '#{prefix}.#{@caml_name}'.");
      CAMLreturn(Qnil);
    }
  }

#{prepare_callback("args")}
  ret = #{callback("*closure", "args")};

  if(Is_exception_result(ret)) {
    *exception = ocaml_exception_string(Extract_exception(ret));
    CAMLreturn(Qnil);
  }

  CAMLreturn(#{dst.caml_to_ruby("ret")});
}

VALUE #{mangled_name(prefix)}
      (#{fmt[formal_args]})
{
  VALUE ret;
  VALUE exception = Qnil;
  int status = 0;

  ret = #{mangled_name(prefix)}_ex(&exception, &status, #{formal_args.join(", ")});

  if(exception == Qnil && !status) {
    return ret;
  } else if(status) { /* exception in Ruby -> caml conversions */
    rb_jump_tag(status);
  } else {            /* OCaml exception*/
    rb_raise(rb_eStandardError, StringValuePtr(exception));
  }

  return Qnil; /* never reached */
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

  def ruby_arity
    if @pass_self
      arity - 1
    else
      arity
    end
  end

  private
  def callback(f, args)
    case ar = arity
    when 0; "caml_callback_exn(#{f}, Val_unit)"
    when 1; "caml_callback_exn(#{f}, #{caml_param_list.first})"
    when 2, 3;
      "caml_callback#{arity}_exn(#{f}, #{caml_param_list.join(", ")})"
    else
      "  caml_callbackN_exn(#{f}, #{arity}, #{args})"
    end
  end

  def prepare_callback(args)
    if @safe
      prepare_callback_safe(args)
    else
      prepare_callback_unsafe(args)
    end
  end

  def prepare_callback_unsafe(args)
    case arity
    when 1
      "  #{caml_param_list.first} = " + @src.ruby_to_caml(param_list.first) + ";"
    when 2, 3
      i = 1
      caml_param_list.zip(param_list).map do |caml, ruby|
        r = "  #{caml} = " + @src[i-1].ruby_to_caml(ruby) + ";"
        i += 1
        r
      end.join("\n")
    else
      i = 1
      param_list.map do |p|
        r = "  #{args}[#{i-1}] = " + @src[i-1].ruby_to_caml(p) + ";"
        i += 1
        r
      end.join("\n")
    end
  end

  def prepare_callback_safe(args)
    case arity
    when 1
      <<-EOF
  #{caml_param_list.first} = #{@src.ruby_to_caml_safe(param_list.first, "status")};
  if(*status) CAMLreturn(Qnil);
      EOF
    when 2, 3
      i = 1
      caml_param_list.zip(param_list).map do |caml, ruby|
        r = "  #{caml} = " + @src[i-1].ruby_to_caml_safe(ruby, "status") + ";" + "\n" +
            "  if(*status) CAMLreturn(Qnil);"
        i += 1
        r
      end.join("\n")
    else
      i = 1
      param_list.map do |p|
        r = "  #{args}[#{i-1}] = " + @src[i-1].ruby_to_caml_safe(p, "status") + ";" + "\n" +
            "  if(*status) CAMLreturn(Qnil);"
        i += 1
        r
      end.join("\n")
    end
  end

  def caml_param_list
    if @pass_self
      ["caml_self"] + (1...arity).map{|i| "caml_param#{i}"}
    else
      # cannot use caml_param, caml_* are reserved
      (1..arity).map{|i| "camlparam#{i}"}
    end
  end

  def param_list
    if @pass_self
      ["self"] + (1...arity).map{|i| "param#{i}"}
    else
      (1..arity).map{|i| "param#{i}"}
    end
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
      def_helper(name, types_and_options, false)
    end

    def method(name, types_and_options)
      def_helper(name, types_and_options, true)
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
      if Types::Type === type && emitted[[direction, type.name]]
        return
      end
      if Types::Type === type
        puts "emitting helper #{type.name}(#{direction})"
      end

      case type
      when Array
        type.each{|x| emit_helper_aux(io, x, emitted, direction)}
      #when Types::Type
      else
        type.type_dependencies.each do |t|
          emit_helper_aux(io, t, emitted, direction)
        end

        case direction
        when :caml_to_ruby
          io.puts type.caml_to_ruby_helper if type.respond_to?(:caml_to_ruby_helper)
        else
          io.puts type.ruby_to_caml_helper if type.respond_to?(:ruby_to_caml_helper)
        end
        io.puts
      end

      if Types::Type === type
        emitted[[direction, type.name]] = true
      end
    end

    private

    PROPAGATED_OPTIONS = [:safe, :aliased_as]

    def def_helper(name, types_and_options, pass_self)
      types_and_options = types_and_options.clone
      raise "Want a type => type mapping" unless Hash === types_and_options
      options = {}
      PROPAGATED_OPTIONS.each do |k|
        options[k] = types_and_options.delete(k) if types_and_options.has_key?(k)
      end
      from = types_and_options.keys.first
      to   = types_and_options[from]
      @mappings << Mapping.new(name, from, to, pass_self, options)
    end
  end

  class Class < Context
    attr_reader :abstract_type

    DEFAULT_OPTIONS = {
      :super => "rb_cObject",
      :under => nil
    }
    def initialize(name, options = {})
      options = DEFAULT_OPTIONS.merge(options)
      super(name)
      @superclass = options[:super]
      @scope      = options[:under]
      @abstract_type = Types::Abstract.new(container_name)
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
        if m.pass_self
          io.puts %[  rb_define_method(#{container_name}, "#{m.name}", #{m.mangled_name(@name)}, #{m.ruby_arity});]
        else
          io.puts %[  rb_define_singleton_method(#{container_name}, "#{m.name}", #{m.mangled_name(@name)}, #{m.ruby_arity});]
        end
      end
    end

    def emit_helpers(io, emitted_helpers)
      # ruby_to_caml before, contains type definition
      emit_helper_aux(io, @abstract_type, emitted_helpers, :ruby_to_caml)
      emit_helper_aux(io, @abstract_type, emitted_helpers, :caml_to_ruby)
      super(io, emitted_helpers)
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
    ret.do_instance_eval(&block)
    ret
  end

  def self.generate(*args, &block)
    define(*args, &block).generate
  end

  DEFAULT_OPTIONS = {
    :dest => nil,
  }

  # Options:
  # dest:: name of destination .c file. NOTE that the generated Makefile
  #        assumes it will match *_rocaml_wrapper.c in the distclean target.
  def initialize(extname, options = {})
    options   = DEFAULT_OPTIONS.merge(options)
    @contexts = []
    @types    = {}
    @extname  = extname
    @dst_file = options[:dest] || "#{extname}_rocaml_wrapper.c"
  end

  def type(name)
    @types[name]
  end

  def variant(name, &block)
    variant = Types::Variant.new(name)
    variant.instance_eval(&block)
    @types[name] = variant
  end

  def def_module(name, options = {}, &block)
    c = Module.new(name, options)
    c.instance_eval(&block)
    @contexts << c
    c
  end

  def def_class(name, options = {}, &block)
    c = Class.new(name, options)
    c.do_instance_eval(&block) if block
    @contexts << c
    c
  end

  def generate
    File.open(@dst_file, "w") do |f|
      f.puts <<EOF
/*
 * Ruby extension generated by rocaml.
 *
 * Do not edit this file; if you need to change something, edit the script
 * that generated it, rocaml.rb, and please consider sending a patch to its
 * author  Mauricio Fernandez <mfp@acm.org>.
 *
 * This file will be overwritten by rocaml when you run extconf.rb.
 */

#include <ruby.h>
#include <st.h>
#include <string.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>

EOF
      @contexts.each{|c| c.emit_container_declaration(f)}
      f.puts <<EOF
static VALUE
do_raise_exception(VALUE klass, char *s)
{
  rb_raise(klass, "%s", s);
  return Qnil; /* not reached */
}

static VALUE
do_raise_exception_tag_aux(VALUE *args)
{
  rb_raise(args[0], "%s", StringValuePtr(args[1]));
  return Qnil;
}

static VALUE
do_raise_exception_tag(VALUE klass, char *s, int *status)
{
  VALUE args[2];
  args[0] = klass;
  args[1] = rb_str_new2(s);
  rb_protect((VALUE (*)(VALUE))do_raise_exception, (VALUE)args, status);
}

static VALUE
ocaml_exception_string(value exn)
{
  CAMLparam1(exn);
  CAMLlocal1(str);
  char exception_text[256];
  static value *closure;

  if(closure == NULL) {
    closure = caml_named_value("Printexc.to_string");
  }

  if(closure) {
    str = caml_callback(*closure, exn);

    snprintf(exception_text, 255, "OCaml exception: %s", String_val(str));
    CAMLreturn(rb_str_new2(exception_text));
  } else {
    CAMLreturn(rb_str_new2("OCaml exception"));
  }
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


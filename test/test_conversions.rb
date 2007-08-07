
require 'test/unit'
require 'rbconfig'
require 'rocaml_tests'

DIR  = File.dirname(File.expand_path(__FILE__))
RUBY = File.join(*%w[bindir ruby_install_name].map{|x| Config::CONFIG[x]})

ITERATIONS = 10

class TestROCamlConversions < Test::Unit::TestCase
  def rocamlrun(f, input, printer = "puts")
    arg = input.nil? ? "" : input.inspect
    cmd = %[ruby -I#{DIR} -rrocaml_tests -e '#{printer} Conversions.#{f}(#{arg})' 2>&1]
    `#{cmd}`.chomp
  end

  def aeq(f, input, expected = input.inspect)
    assert_equal(expected, rocamlrun(f, input))
  end

  def atyp(f, input)
    out = rocamlrun(f, input)
    assert(out.include?("(TypeError)"),
           "Expected TypeError (#{input.inspect} -> #{f}) but got #{out.inspect}")
  end

  def test_bool
    aeq("bool", true)
    aeq("bool", false)
  end

  def test_int
    ITERATIONS.times{ aeq("int", rand(1000) - 500) }
  end

  def test_int_auto_conversions
    ITERATIONS.times{ x = rand * 100; aeq("int", x, x.to_i.to_s) }
  end

  def test_int_typecheck
    ["bogus", true, false].each{|x| atyp("int", x) }
  end

  def test_big_int
    ITERATIONS.times{ aeq("big_int", rand(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) }
  end

  def rand_float
    # string_of_float and Float#to_s differ for integers: 1. vs 1.0
    # so need to generate appropriate values, also take into account
    # rounding
    (1 + rand(128)) / 256.0
  end

  def test_float
    ITERATIONS.times{ aeq("float", rand_float) }
  end

  def test_float_auto_conversions
    aeq("float", 42, "42.0")
  end

  def test_float_typecheck
    ["bogus", true, false].each{|x| atyp("int", x) }
  end

  def test_string
    ITERATIONS.times do
      x = rand(100000).to_s
      aeq("string", x, x)
    end
    s = "ads\0asdsad\0"
    aeq("string", s, s)
  end

  def test_string_typecheck
    [42.0, 42, true, false ].each{|x| atyp("string", x) }
  end

  def test_unit
    aeq("unit", nil, "nil")
  end

  def aux_test(type, kind)
    ITERATIONS.times do
      a = yield
      aeq("#{type}_#{kind}", a, a.inspect)
    end
  end

  def aux_test_array(arr_or_list, type, &block)
    aux_test(type, arr_or_list) { (1..50).map{|x| yield } }
  end

  %w[array list].each do |t|
    define_method("test_bool_#{t}") do
      aux_test_array(t, "bool"){ rand > 0.5 }
    end
    define_method("test_int_#{t}") do
      aux_test_array(t, "int"){ rand(100001) - 50000 }
    end
    define_method("test_float_#{t}") do
      aux_test_array(t, "float"){ rand_float }
    end
    define_method("test_string_#{t}") do
      aux_test_array(t, "string"){ rand(1000000).to_s }
    end
    define_method("test_int_#{t}_#{t}") do
      aux_test_array(t, "int_#{t}"){ (1..2 + rand(10)).map{ rand(1000) } }
    end
    define_method("test_float_#{t}_#{t}") do
      aux_test_array(t, "float_#{t}"){ (1..2 + rand(10)).map{ rand_float } }
    end
  end

  def test_int_tuple2
    aux_test("int", "tuple2"){ [rand(100000), rand(100000)] }
  end

  def test_float_tuple2
    aux_test("float", "tuple2"){ [rand_float, rand_float] }
  end

  def test_int_float_tuple2
    aux_test("int_float", "tuple2"){ [rand(100000), rand_float] }
  end

  def test_string_tuple2
    aux_test("string", "tuple2"){ ["bar " + rand(100000).to_s, "foo" + rand_float.to_s] }
  end

  def test_take_and_return_complex_tuple
    x = ["foobar", 42, 0.0125, true]
    out = rocamlrun("string_int_float_bool_tuple4", x, "p")
    assert_equal(%(["foobar", 42, 0.0125, true]), out)
  end

  def test_abstract_types
    t1 = Conversions::T1.new
    t2 = Conversions::T2.new
    assert_raise(TypeError){ t1.f(t2) }
  end
end

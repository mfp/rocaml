
require 'test/unit'
require 'rbconfig'

DIR  = File.dirname(File.expand_path(__FILE__))
RUBY = File.join(*%w[bindir ruby_install_name].map{|x| Config::CONFIG[x]})

ITERATIONS = 10

class TestROCamlConversions < Test::Unit::TestCase
  def rocamlrun(f, input)
    arg = input.nil? ? "" : input.inspect
    cmd = %[ruby -I#{DIR} -rrocaml_tests -e 'puts Conversions.#{f}(#{arg})' 2>&1]
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

  def test_float
    ITERATIONS.times{ aeq("float", 1.0 - rand) }
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
  end

  def test_string_typecheck
    [42.0, 42, true, false ].each{|x| atyp("string", x) }
  end

  def test_unit
    aeq("unit", nil, "nil")
  end

  def aux_test_array(type)
    ITERATIONS.times do
      a = (1..50).map{|x| yield }
      aeq("#{type}_array", a, a.inspect)
    end
  end

  def test_bool_array
    aux_test_array("bool"){ rand > 0.5 }
  end

  def test_int_array
    aux_test_array("int"){ rand(100001) - 50000 }
  end

  def test_float_array
    aux_test_array("float") do
      # string_of_float and Float#to_s differ for integers: 1. vs 1.0
      # so need to generate appropriate values, also take into account
      # rounding
      (1 + rand(128)) / 256.0
    end
  end

  def test_string_array
    aux_test_array("string"){ rand(1000000).to_s }
  end

  def test_int_array_array
    aux_test_array("int_array"){ (1..2 + rand(10)).map{ rand(1000) } }
  end

  def test_float_array_array
    aux_test_array("float_array"){ (1..2 + rand(10)).map{ (1 + rand(128)) / 256.0 } }
  end
end

require 'oo'

o = Oo.new_from_string "42"
p o.get
o.inc
o.inc
p o.get

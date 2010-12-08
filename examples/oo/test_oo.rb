## rocaml Copyright (c) 2007-2010 Mauricio Fernandez <mfp@acm.org>
##                                http://eigenclass.org
## Use and redistribution subject to the same conditions as Ruby.
## See the LICENSE file included in rocaml's distribution for more
## information.

require 'oo'

o = Oo.new_from_string "42"
p o.get
o.inc
o.inc
p o.get
o.dec
p o.get

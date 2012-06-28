#!/bin/sh
exec bin/scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8 "$0" "$@" 
!# 
// Local Variables:
// mode: scala
// End:

// finds models with spelling mistakes (because yea, verily,
// spelling mistakes are an abomination unto the Lord)

// installing aspell: brew install aspell --lang=en

import Scripting.shell

val ignores = List("/3D/", "/Curricular Models/Urban Suite/", "/test/")

for{path <- shell("find models -name \\*.nlogo")
    if ignores.forall(!path.containsSlice(_))
    lines = shell("cat \"" + path + "\" | sed -e 's/\\\\n/ /g' | aspell -H -p ./dist/modelwords.txt list")
    if lines.hasNext}
{
  println(path)
  lines.foreach(line => println("  " + line))
}

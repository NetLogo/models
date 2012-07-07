#!/bin/sh
exec bin/scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8 "$0" "$@"
!#

// finds models with spelling mistakes (because yea, verily,
// spelling mistakes are an abomination unto the Lord)

// installing aspell: brew install aspell --lang=en

import sys.process.Process
import java.io.File

val ignores = List("/3D/", "/Curricular Models/Urban Suite/", "/test/")

for{path <- Process("find models -name *.nlogo -or -name *.nlogo3d").lines
    if ignores.forall(!path.containsSlice(_))
    lines = (Process(new File(path)) #> "aspell --encoding=UTF-8 -H -p ./dist/modelwords.txt list").lines
    if lines.nonEmpty}
{
  println(path)
  lines.map("  " + _).foreach(println)
}

// Local Variables:
// mode: scala
// End:

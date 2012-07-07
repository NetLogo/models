#!/bin/sh
exec bin/scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8 "$0" "$@"
!#

// finds models with non-integer patch sizes (because yea, verily,
// non-integer patch sizes are an abomination)

import sys.process.Process

println
for{path <- Process("find models -name *.nlogo -o -name *.nlogo3d").lines
    patchSize = io.Source.fromFile(path).getLines
                  .dropWhile(_ != "GRAPHICS-WINDOW")
                  .takeWhile(!_.isEmpty).drop(7).next
    if !patchSize.endsWith(".0")}
  println(path + ": " + patchSize)

// Local Variables:
// mode: scala
// End:

#!/bin/sh
exec bin/scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8 "$0" "$@"
!#

// finds models with tabs anywhere in them
// (because yea, verily, tabs are an abomination)

import sys.process.Process

def read(s: String) = io.Source.fromFile(s).getLines

Process("find models -name *.nlogo -o -name *.nlogo3d")
  .lines
  .filter(read(_).exists(_.contains('\t')))
  .foreach(println(_))

// Local Variables:
// mode: scala
// End:

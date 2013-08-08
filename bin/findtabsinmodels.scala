#!/usr/bin/env scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8
!#

// finds models with tabs anywhere in them
// (because yea, verily, tabs are an abomination)

import sys.process.Process

def read(s: String) = io.Source.fromFile(s).getLines

Process("find models -name *.nlogo -o -name *.nlogo3d")
  .lines
  .filter(read(_).exists(_.contains('\t')))
  .foreach(println(_))

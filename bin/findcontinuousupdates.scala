#!/usr/bin/env scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8
!#

// find models that use continuous updates (instead of tick based)

// some older models have short GRAPHICS-WINDOW sections which
// means they default to continuous. if there is an explicit
// setting of 1 or 0, 0 means continuous.

// note we skip 3D models for now because we're lazy and 3D models
// are a pain because the updates setting is on a different line
// than 2D models use

import sys.process.Process

def read(s: String) = io.Source.fromFile(s).getLines

Process("find models -name *.nlogo -o -name *.nlogo3d")
  .lines
  .filter(!_.containsSlice("/3D/"))
  .filter(!read(_).dropWhile(_ != "GRAPHICS-WINDOW")
                  .takeWhile(!_.isEmpty)
                  .drop(21).take(1).contains("1"))
  .foreach(println(_))

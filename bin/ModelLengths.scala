#!/usr/bin/env scala -classpath bin -deprecation -nocompdaemon -Dfile.encoding=UTF-8
//!#

/// print and histogram the lengths of the Code tabs of all Sample Models
import sys.process.Process

println("Counting lines containing something besides a bracket or paren and/or a comment.")
// See below comment. 11-18-2020 CPB
//println("Of the GasLab suite, only Circular Particles and Gas in a Box are included.")
println

System.setProperty( "user.dir", "../" )

def hasActualCode(line:String):Boolean =
  line.matches(""".*\S.*""") &&               // ignore blank lines
  !line.matches("""\s*[\[\]\(\)]\s*""") &&    // ignore if nothing but a bracket/paren
  !line.matches("""\s*;.*""") &&              // ignore if nothing but a comment
  !line.matches("""\s*[\[\]\(\)]\s*;.*""")    // ignore if nothing but a bracket/paren and a comment

val hash = collection.mutable.HashMap[String,Int]()
for {
   path <- Process(Seq("find", "./", "-name", "*.nlogo", "-o", "-name", "*.nlogo3d", "-o", "-name", "*.nlogox")).lineStream
    name = path.split("/").last.stripSuffix(".nlogo")
    if !path.containsSlice("/System Dynamics/")
    // The below exception was likely due to the fact that the GasLab models are
    // A) incredibly long; B) share similar underlying mechanical code.
    // 11-18-2020 CPB
    //if !path.containsSlice("/GasLab/") || List("GasLab Circular Particles","GasLab Gas in a Box").contains(name)
}

hash += name -> io.Source.fromFile(path).getLines.takeWhile(_ != "@#$#@#$#@").count(hasActualCode)
println(hash.size + " models total")
println

for(bin <- hash.values.max / 25 to 0 by -1) {
  val (min,max) = (bin * 25,bin * 25 + 24)
  val count = hash.values.count((min to max).contains)
  printf("%3d-%3d = %s (%d)\n",min,max,List.fill(count)('*').mkString,count)
}
println

for(name <- hash.keys.toList.sortBy(hash).reverse)
  printf("%4d %s\n",hash(name),name)

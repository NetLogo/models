scalaVersion := "2.11.6"

scalacOptions ++= Seq("-feature", "-unchecked", "-deprecation")

resolvers += "Typesafe Repo" at "http://repo.typesafe.com/typesafe/releases/"

libraryDependencies ++= Seq(
  "org.nlogo" % "NetLogo" % "5.3.0" from
    "http://ccl.northwestern.edu/devel/NetLogo-5.3-17964bb.jar",
  "asm" % "asm-all" % "3.3.1",
  "org.picocontainer" % "picocontainer" % "2.13.6",
  "org.scalatest" %% "scalatest" % "2.2.4" % Test,
  "commons-io" % "commons-io" % "2.4",
  "commons-validator" % "commons-validator" % "1.4.1",
  "com.typesafe.play" %% "play-ws" % "2.3.8",
  "org.pegdown" % "pegdown" % "1.1.0",
  "com.github.wookietreiber" %% "scala-chart" % "0.4.2",
  "org.jfree" % "jfreesvg" % "3.0"
)

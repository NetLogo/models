lazy val netLogoVersion = "6.2.2"

scalaVersion := "2.12.12"

scalacOptions ++= Seq("-feature", "-unchecked", "-deprecation")

resolvers ++= Seq(
  "Typesafe Repo"   at "https://repo.typesafe.com/typesafe/releases/"
, "netlogoheadless" at "https://dl.cloudsmith.io/public/netlogo/netlogo/maven/"
)

javaOptions ++= Seq(
  "-Dorg.nlogo.onLocal=" + Option(System.getProperty("org.nlogo.onLocal")).getOrElse("false"),
  "-Dorg.nlogo.is3d=" + Option(System.getProperty("org.nlogo.is3d")).getOrElse("false"),
  "-Dcom.sun.media.jai.disableMediaLib=true", // see https://github.com/NetLogo/GIS-Extension/issues/4
  "-Xmx4G"
)

fork := true

libraryDependencies ++= Seq(
  "org.nlogo" % "netlogo" % netLogoVersion,
  "org.scalatest" %% "scalatest" % "3.0.1" % Test,
  "commons-io" % "commons-io" % "2.4",
  "commons-validator" % "commons-validator" % "1.4.1",
  "org.jogamp.jogl" % "jogl-all" % "2.4.0" from "https://jogamp.org/deployment/archive/rc/v2.4.0-rc-20210111/jar/jogl-all.jar",
  "org.jogamp.gluegen" % "gluegen-rt" % "2.4.0" from "https://jogamp.org/deployment/archive/rc/v2.4.0-rc-20210111/jar/gluegen-rt.jar",
  "org.apache.commons" % "commons-lang3" % "3.5",
  "org.asynchttpclient" % "async-http-client" % "2.0.24",
  "com.github.wookietreiber" %% "scala-chart" % "0.5.1",
  "com.googlecode.java-diff-utils" % "diffutils" % "1.2" % "test",
  "org.jfree" % "jfreesvg" % "3.0",
  "com.typesafe" % "config" % "1.3.1" % "test",
  "com.vladsch.flexmark" % "flexmark" % "0.20.0" % "test",
  "com.vladsch.flexmark" % "flexmark-ext-autolink" % "0.20.0" % "test",
  "com.vladsch.flexmark" % "flexmark-util" % "0.20.0" % "test"
)

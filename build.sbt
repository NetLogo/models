lazy val netLogoVersion = "7.0.0-beta0"

scalaVersion := "2.13.16"

scalacOptions ++= Seq("-feature", "-unchecked", "-deprecation", "-Xfatal-warnings")

resolvers ++= Seq(
  "Typesafe Repo"   at "https://repo.typesafe.com/typesafe/releases/"
, "netlogoheadless" at "https://dl.cloudsmith.io/public/netlogo/netlogo/maven/"
)

javaOptions ++= Seq(
  "-Dorg.nlogo.onLocal=" + Option(System.getProperty("org.nlogo.onLocal")).getOrElse("false"),
  "-Dorg.nlogo.is3d=" + Option(System.getProperty("org.nlogo.is3d")).getOrElse("false"),
  "-Dcom.sun.media.jai.disableMediaLib=true", // see https://github.com/NetLogo/GIS-Extension/issues/4
  "-Dnetlogo.extensions.dir=" + (baseDirectory.value.getParentFile / "extensions").getAbsolutePath.toString,
  "-Xmx4G"
)

fork := true

libraryDependencies ++= Seq(
  "org.nlogo" % "netlogo" % netLogoVersion,
  "org.scalatest" %% "scalatest" % "3.2.19" % Test,
  "org.scala-lang.modules" %% "scala-parallel-collections" % "1.2.0",
  "commons-io" % "commons-io" % "2.4",
  "commons-validator" % "commons-validator" % "1.4.1",
  "org.jogamp.jogl" % "jogl-all" % "2.4.0" from "https://jogamp.org/deployment/archive/rc/v2.4.0/jar/jogl-all.jar",
  "org.jogamp.gluegen" % "gluegen-rt" % "2.4.0" from "https://jogamp.org/deployment/archive/rc/v2.4.0/jar/gluegen-rt.jar",
  "org.apache.commons" % "commons-lang3" % "3.5",
  "org.asynchttpclient" % "async-http-client" % "2.12.3",
  "com.googlecode.java-diff-utils" % "diffutils" % "1.2" % "test",
  "org.jfree" % "jfreechart" % "1.0.19",
  "org.jfree" % "jfreesvg" % "3.0",
  "com.typesafe" % "config" % "1.3.1" % "test",
  "com.vladsch.flexmark" % "flexmark" % "0.20.0" % "test",
  "com.vladsch.flexmark" % "flexmark-ext-autolink" % "0.20.0" % "test",
  "com.vladsch.flexmark" % "flexmark-util" % "0.20.0" % "test",
  "org.json4s" %% "json4s-jackson" % "4.0.7"
)

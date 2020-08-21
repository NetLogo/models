lazy val netLogoVersion = "6.1.1"

scalaVersion := "2.12.8"

scalacOptions ++= Seq("-feature", "-unchecked", "-deprecation")

resolvers += "Typesafe Repo" at "https://repo.typesafe.com/typesafe/releases/"
resolvers += sbt.Resolver.bintrayRepo("netlogo", "NetLogo-JVM")

javaOptions ++= Seq(
  "-Dorg.nlogo.is3d=" + Option(System.getProperty("org.nlogo.is3d")).getOrElse("false"),
  "-Dcom.sun.media.jai.disableMediaLib=true", // see https://github.com/NetLogo/GIS-Extension/issues/4
  "-Xmx4G" // extra memory to work around https://github.com/travis-ci/travis-ci/issues/3775
)

fork := true

libraryDependencies ++= Seq(
  "org.nlogo" % "netlogo" % netLogoVersion,
  "org.scalatest" %% "scalatest" % "3.0.0" % Test,
  "commons-io" % "commons-io" % "2.4",
  "commons-validator" % "commons-validator" % "1.4.1",
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

scalaVersion := "2.12.0"

scalacOptions ++= Seq("-feature", "-unchecked", "-deprecation")

resolvers += "Typesafe Repo" at "http://repo.typesafe.com/typesafe/releases/"

javaOptions ++= Seq(
  "-Dorg.nlogo.is3d=" + Option(System.getProperty("org.nlogo.is3d")).getOrElse("false"),
  "-Dnetlogo.extensions.dir=" + (baseDirectory in netLogo).value.getParentFile.getPath + "/extensions/",
  "-Dcom.sun.media.jai.disableMediaLib=true", // see https://github.com/NetLogo/GIS-Extension/issues/4
  "-Xmx4G" // extra memory to work around https://github.com/travis-ci/travis-ci/issues/3775
)

fork := true

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "3.0.0" % Test,
  "commons-io" % "commons-io" % "2.4",
  "commons-validator" % "commons-validator" % "1.4.1",
  "org.apache.commons" % "commons-lang3" % "3.5",
  "org.asynchttpclient" % "async-http-client" % "2.0.24",
  "com.github.wookietreiber" %% "scala-chart" % "0.5.1",
  "org.jfree" % "jfreesvg" % "3.0"
)

(test in Test) <<= (test in Test) dependsOn {
  Def.task {
    EvaluateTask(
      buildStructure.value,
      extensionsKey,
      state.value,
      buildStructure.value.allProjectRefs.find(_.project.contains("netlogo")).get
    )
  }
}

scalaVersion := "2.11.6"

resolvers += "Typesafe Repo" at "http://repo.typesafe.com/typesafe/releases/"

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "2.2.4" % Test,
  "commons-io" % "commons-io" % "2.4" % Test,
  "commons-validator" % "commons-validator" % "1.4.1" % Test,
  "com.typesafe.play" %% "play-ws" % "2.3.8" % Test,
  "org.pegdown" % "pegdown" % "1.5.0" % Test
)

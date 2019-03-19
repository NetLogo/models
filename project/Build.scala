import sbt._

object MyBuild {
  lazy val netLogo = ProjectRef(uri("git://github.com/NetLogo/NetLogo.git#ising"), "netlogo")

  lazy val extensionsKey =
    Def.ScopedKey[Task[Seq[File]]](Scope(This, This, This, This) in netLogo, AttributeKey[Task[Seq[File]]]("extensions"))
}

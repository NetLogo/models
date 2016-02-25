package org.nlogo.models

import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.Files
import java.nio.file.Paths
import Model.libraryModels
import org.nlogo.lex.TokenMapper
import org.nlogo.api.TokenHolder
import org.nlogo.nvm.Instruction
import org.nlogo.api.Syntax
import org.nlogo.api.Syntax._

object CodeComplexity {

  val models = libraryModels.filterNot(_.file.getPath.contains("Code Examples"))

  val syntacticTypeCosts: Seq[(Int, Double)] = Seq(
    1 -> Seq(NumberType, BooleanType, StringType),
    2 -> Seq(AgentType, NobodyType, ReferenceType),
    4 -> Seq(AgentsetType, CommandBlockType, ReporterBlockType),
    8 -> Seq(ListType),
    16 -> Seq(CommandTaskType, ReporterTaskType)
  ).flatMap { case (k, vs) => vs.map(_ -> k.toDouble) }

  def syntaxCost(syntax: Syntax): Double =
    1.0 + (for {
      t <- syntax.ret +: syntax.left +: syntax.right
      (_, cost) <- syntacticTypeCosts.find { case (const, _) => Syntax.compatible(const, t) }
    } yield cost).sum

  val syntacticCosts: Map[String, Double] = {
    def cost(th: TokenHolder) =
      syntaxCost(th.asInstanceOf[Instruction].syntax)
    val tm = new TokenMapper(true)
    models.flatMap(_.primitiveTokenNames).toSet.map {
      (_: String) match {
        case t if tm.isVariable(t) => t -> 1.0
        case t if tm.isReporter(t) => t -> cost(tm.getReporter(t))
        case t if tm.isCommand(t)  => t -> cost(tm.getCommand(t))
      }
    }(collection.breakOut)
  }

  val usageCosts: Map[String, Double] =
    models.flatMap(_.primitiveTokenNames)
      .groupBy(identity)
      .mapValues(1.0 / _.size)

  def format(xs: Iterable[(String, Double)]) =
    xs.toSeq.sortBy(_._2)
      .map { case (s, d) => s"$s, $d" }
      .mkString("\n")

  def main(args: Array[String]): Unit = {
    println(format(models.map(m => m.name -> m.primitiveTokenNames.map(usageCosts).sum)))
  }

}

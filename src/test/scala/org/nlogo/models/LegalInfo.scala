package org.nlogo.models

import java.io.File
import java.util.Calendar

/**
 *
 * (What follows is taken from `legal.txt`. It should probably be turned
 * into a wiki page at some point, but I'm storing it here while I'm
 * still working on the new way of doing things... -- NP 2015-05-28)
 *
 * ###
 * ### HOW TO SPECIFY COPYRIGHTS
 * ###
 * # Models that were included in 3.0 are being handled an old way;
 * # there's a newer way for models that are new for 3.1 and future
 * # releases.
 * #
 * # OLD (3.0 AND PRIOR) MODELS:
 * # The copyright year is just copied from whatever the model already
 * # said (unless it was obviously grossly wrong).  The idea is not
 * # to rock the boat, since the existing copyright years may already
 * # have been cited in various places.
 * #
 * # NEW (3.1 AND FUTURE) MODELS:
 * # At the time you add the model here, attach the current year.
 * #
 * # SPECIAL HANDLING FOR CONVERTED STARLOGOT MODELS:
 * # Models converted from StarLogoT need two years specified: the
 * # original's copyright year (which becomes the NetLogo version's
 * # copyright year as well) and the year of conversion.  To determine
 * # the year of conversion, follow the same rules given above for
 * # 3.0-and-before versus 3.1-and-after.
 * #
 * # OTHER OPTIONS:
 * # You can add one of the following keywords to cause a model to be
 * # handled specially:
 * #  - specialCE      in Code Examples directory, but gets normal copyright
 * #  - MIT            created at MIT, Resnick ref
 * #  - Steiner        Creative Commons license, includes code by James Steiner
 * #  - MAC            credit the MAC grant
 * #  - NIELS          copyright & cite info both include Pratim
 * #  - ConChem        include how-to-cite info for the curriculum
 * #  - Stroup         copyright & cite info both include Walter
 * #  - Wilensky       created at MIT, Wilensky ref
 * #  - Cite           should always appear last and be followed by a colon and the
 * #                   names of the collaborators <lastname>, <firstinitial>.
 * #                   It is ok to add multiple names in a single line; see Erosion
 * #                   for example.  Uri need not be included; he will be added
 * #                   automatically at the end.
 * #  - 3D             3D models that were directly converted from existing 2D models
 * #                   They should already have the same name as the 2D model with 3D
 * #                   attached to the end.
 * #
 * ######################################################################
 * #
 * # CODE EXAMPLES
 * #
 * # notarize.scala automatically handles stuff in this directory
 * # differently (unless it has the specialCE keyword)
 * #
 * # HUBNET ACTIVITIES
 * #
 * # notarize.scala automatically handles HubNet specially
 * #
 * # Curricular models
 * #
 * # Most models in "Curricular models" are copied at release time
 * # from other directories.  These copyrights only affect the models
 * # that are directly committed to "Curricular models".
 */

object LegalInfo {
  val pattern =
    """<!-- (\d\d\d\d)( \d\d\d\d)?(( \w+)*)( Cite: .*)? -->""".r
  val validKeywords = List(
    "MIT", "Wilensky", "specialCE", "MAC", "Steiner",
    "Stroup", "3D", "NIELS", "ConChem", "CC0", "BYSA")
  val textbookCitation =
    "* Wilensky, U. & Rand, W. (2015). Introduction " +
      "to Agent-Based Modeling: Modeling Natural, Social " +
      "and Engineered Complex Systems with NetLogo. " +
      "Cambridge, MA. MIT Press.\n"
}

case class LegalInfo(model: Model) {

  import LegalInfo._

  val (year: Int, year2: Option[Int], keywords: List[String], cite: String) = {
    val pattern(y1, y2, keys, _, cite) = model.info.legalSnippet
    (y1.toInt,
      if (y2 == null) None else Some(y2.trim.toInt),
      if (keys == null) List() else keys.split("""\s""").map(_.trim).filter(!_.isEmpty).toList,
      if (cite == null) "" else cite.drop(" Cite: ".size).toString)
  }

  private val currentYear = Calendar.getInstance().get(Calendar.YEAR)

  for (y <- year +: year2.toSeq)
    require(y >= 1996 && y <= currentYear, "invalid year: " + y)

  for (k <- keywords)
    require(validKeywords.contains(k), "invalid keyword: " + k)

  val isCodeExample = model.file.getPath.contains("Code Examples/")

  if (keywords.contains("specialCE"))
    require(isCodeExample, "specialCE keyword is only for code examples")

  val path = model.file.getPath.drop(2)

  val netlogohubnet =
    if (model.isHubNet) "NetLogo HubNet"
    else "NetLogo"

  val copyrightString = {
    if (keywords.contains("Steiner"))
      "Copyright " + year + " Uri Wilensky. Includes code by James P. Steiner. "
    else if (keywords.contains("Stroup"))
      "Copyright " + year + " Uri Wilensky and Walter Stroup."
    else if (keywords.contains("NIELS"))
      "Copyright " + year + " Pratim Sengupta and Uri Wilensky."
    else if (keywords.contains("CC0") || (isCodeExample && !keywords.contains("specialCE")))
      "Public Domain"
    else
      "Copyright " + year + " Uri Wilensky."
  }

  val codeCopyright: String = {
    val result = if (keywords.contains("CC0") || (isCodeExample && !keywords.contains("specialCE"))) {
      require(!year2.isDefined, "can't specify two years for code examples")
      "; " + copyrightString + ":\n" +
        "; To the extent possible under law, Uri Wilensky has waived all\n" +
        "; copyright and related or neighboring rights to this model.\n"
    } else
      "; " + copyrightString + "\n" + "; See Info tab for full copyright and license.\n"
    Info.clean(result)
  }

  val code = model.code.lines.toSeq
    .reverse.dropWhile(_.startsWith(";")).reverse
    .mkString("", "\n", "\n") + codeCopyright + "\n"

  def modelCitation: String = {
    val builder = new StringBuilder
    val authors = cite match {
      case "" if keywords.contains("Stroup") =>
        "Wilensky, U. and Stroup, W."
      case "" => "Wilensky, U."
      case _ if cite contains "Wilensky" => cite
      case _ => cite + " and Wilensky, U."
    }
    builder.append(authors)
    builder.append(" (" + year + ").  " + netlogohubnet + " " + model.name + " model.  ")
    builder.append("http://ccl.northwestern.edu/netlogo/models/" + model.compressedName + ".  ")
    builder.append("Center for Connected Learning and Computer-Based Modeling, ")
    if (model.isIABM) builder.append("Northwestern Institute on Complex Systems, ")
    builder.append("Northwestern University, Evanston, IL.")
    builder.result
  }

  val acknowledgment: Option[String] = {
    val iabm = """.*\/IABM Textbook\/chapter ([0-9])\/.*""".r
    val altViz = """.*\/Alternative Visualizations/(.*) - .*""".r
    model.file.getPath match {
      case iabm(chapter) =>
        Vector("Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight")
          .lift(chapter.toInt)
          .map { n =>
            val builder = new StringBuilder
            builder.append(s"This model is from Chapter $n of the book ")
            builder.append("\"Introduction to Agent-Based Modeling: ")
            builder.append("Modeling Natural, Social and Engineered ")
            builder.append("Complex Systems with NetLogo\", ")
            builder.append("by Uri Wilensky & William Rand.\n")
            builder.append("\n")
            builder.append(textbookCitation + "\n")
            builder.append("This model is in the IABM Textbook folder of the ")
            builder.append("NetLogo Models Library. The model, as well as any ")
            builder.append("updates to the model, can also be found on the ")
            builder.append("textbook website: http://www.intro-to-abm.com/.")
            builder.result()
          }
      case altViz(original) =>
        val originalFolder = Model.models
          .find(_.baseName == original).get
          .file.getPath.split(File.separator)
          .dropWhile(_ != "Sample Models").drop(1).head
        val builder = new StringBuilder
        builder.append(s"This model is an alternate visualization of the $original model ")
        builder.append(s"from the $originalFolder section of the NetLogo Models Library. ")
        builder.append("It uses visualization techniques as recommended in the paper:\n")
        builder.append("\n")
        builder.append("* Kornhauser, D., Wilensky, U., & Rand, W. (2009). ")
        builder.append("Design guidelines for agent based model visualization. ")
        builder.append("Journal of Artificial Societies and Social Simulation (JASSS), 12(2), 1. ")
        builder.append("http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf.")
        Some(builder.result)
      case _ => None
    }
  }

  val creditsAndReferences: Option[String] = {
    val current = model.info.sectionMap.get(Info.CreditsAndReferences.name)
    if (model.isIABM && model.name.contains("Simple")) {
      val thisModelIs = "This model is a simplified version of:\n\n"
      val originalName =
        if (model.name.startsWith("Wolf Sheep")) "Wolf Sheep Predation"
        else model.name.split("Simple").head.trim
      Model.models.find(_.name == originalName).map { m =>
        val rest = current.map { s =>
          (if (s.startsWith(thisModelIs)) s.lines.drop(4).mkString("\n") else s)
        }.map(s => if (s.nonEmpty) s"\n\n$s" else s).getOrElse("")
        thisModelIs + "* " + m.legalInfo.modelCitation + rest
      }
    } else model.info.sectionMap.get(Info.CreditsAndReferences.name)
  }
  val howToCite: String = {
    val builder = new StringBuilder
    if (!isCodeExample) {
      if (model.isIABM) {
        builder.append("This model is part of the textbook, “Introduction to ")
        builder.append("Agent-Based Modeling: Modeling Natural, Social and ")
        builder.append("Engineered Complex Systems with NetLogo.”\n\n")
      }
      builder.append("If you mention this model or the NetLogo software in a publication, ")
      builder.append("we ask that you include the citations below.\n\n")

      builder.append("For the model itself:\n\n")
      builder.append("* " + modelCitation + "\n\n")

      builder.append("Please cite the NetLogo software as:\n\n")

      builder.append("* Wilensky, U. (1999). NetLogo. ")
      builder.append("http://ccl.northwestern.edu/netlogo/. ")
      builder.append("Center for Connected Learning and ")
      builder.append("Computer-Based Modeling, Northwestern University, Evanston, IL.\n")

      if (model.isIABM) {
        builder.append("\n")
        builder.append("Please cite the textbook as:\n\n")
        builder.append(textbookCitation)
      }
      if (keywords.contains("NIELS")) {
        builder.append("\n")
        builder.append("To cite the NIELS curriculum as a whole, please use:\n\n")
        builder.append("* Sengupta, P. and Wilensky, U. (2008). NetLogo NIELS curriculum. ")
        builder.append("http://ccl.northwestern.edu/NIELS/. ")
        builder.append("Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.\n")
      }
      if (keywords.contains("ConChem")) {
        builder.append("\n")
        builder.append("To cite the Connected Chemistry curriculum as a whole, please use:\n\n")
        builder.append("* Wilensky, U., Levy, S. T., & Novak, M. (2004). ")
        builder.append("Connected Chemistry curriculum. ")
        builder.append("http://ccl.northwestern.edu/curriculum/chemistry/. ")
        builder.append("Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.\n")
      }
    }
    Info.clean(builder.toString)
  }

  val copyrightAndLicence: String = {
    val builder = new StringBuilder
    if (!isCodeExample) {
      if (keywords.contains("Steiner")) {
        builder.append(copyrightString + "\n")
        builder.append("\n")
        builder.append("This work is licensed under the Creative Commons ")
        builder.append("Attribution-NonCommercial-ShareAlike 2.5 License.  To view a copy of ")
        builder.append("this license, visit http://creativecommons.org/licenses/by-nc-sa/2.5/ ")
        builder.append("or send a letter to Creative Commons, 559 Nathan Abbott Way, ")
        builder.append("Stanford, California 94305, USA.\n")
      } else if (keywords.contains("CC0")) {
        builder.append("[![CC0](http://ccl.northwestern.edu/images/creativecommons/zero.png)](http://creativecommons.org/publicdomain/zero/1.0/)\n")
        builder.append("\n")
        builder.append(copyrightString + ": ")
        builder.append("To the extent possible under law, Uri Wilensky has waived all ")
        builder.append("copyright and related or neighboring rights to this model.")
        builder.append("\n")
      } else if (keywords.contains("BYSA")) {
        builder.append(copyrightString + "\n")
        builder.append("\n")
        builder.append("![CC BY-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/bysa.png)\n")
        builder.append("\n")
        builder.append("This work is licensed under the Creative Commons ")
        builder.append("Attribution-ShareAlike 3.0 License.  To view a copy of ")
        builder.append("this license, visit http://creativecommons.org/licenses/by-sa/3.0/ ")
        builder.append("or send a letter to Creative Commons, 559 Nathan Abbott Way, ")
        builder.append("Stanford, California 94305, USA.\n")
        builder.append("\n")
        builder.append("Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.\n")
        builder.append("\n")
      } else { // default license is CC BY-NC-SA
        builder.append(copyrightString + "\n")
        builder.append("\n")
        builder.append("![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)\n")
        builder.append("\n")
        builder.append("This work is licensed under the Creative Commons ")
        builder.append("Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of ")
        builder.append("this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ ")
        builder.append("or send a letter to Creative Commons, 559 Nathan Abbott Way, ")
        builder.append("Stanford, California 94305, USA.\n")
        builder.append("\n")
        builder.append("Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.\n")
        builder.append("\n")
      }
      if (keywords.contains("3D"))
        builder.append("This is a 3D version of the 2D model " + model.baseName + ".\n\n")
      if (year2.isDefined) {
        builder.append("This model was created as part of the project: CONNECTED MATHEMATICS: ")
        builder.append("MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL ")
        builder.append("MODELS (OBPML).  The project gratefully acknowledges the support of the ")
        builder.append("National Science Foundation (Applications of Advanced Technologies ")
        builder.append("Program) -- grant numbers RED #9552950 and REC #9632612.\n")
        builder.append("\n")
      } else if (keywords.contains("MAC")) {
        builder.append("This model and associated activities and materials were created as ")
        builder.append("part of the project: MODELING ACROSS THE CURRICULUM.  The project ")
        builder.append("gratefully acknowledges the support of the National Science Foundation, ")
        builder.append("the National Institute of Health, and the Department of Education ")
        builder.append("(IERI program) -- grant number REC #0115699.")
        if (year <= 2004) {
          builder.append(" Additional support ")
          builder.append("was provided through the projects: PARTICIPATORY SIMULATIONS: ")
          builder.append("NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or ")
          builder.append("INTEGRATED SIMULATION AND MODELING ENVIRONMENT -- NSF (REPP & ROLE ")
          builder.append("programs) grant numbers REC #9814682 and REC-0126227.")
        }
        builder.append("\n\n")
      } else if (year <= 2004) {
        if (path.startsWith("HubNet Activities/") &&
          !path.startsWith("HubNet Activities/Code Examples/"))
          builder.append("This activity and associated models and materials were created as part of the projects: ")
        else
          builder.append("This model was created as part of the projects: ")
        builder.append("PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN ")
        builder.append("CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. ")
        builder.append("The project gratefully acknowledges the support of the ")
        builder.append("National Science Foundation (REPP & ROLE programs) -- ")
        builder.append("grant numbers REC #9814682 and REC-0126227.\n")
        builder.append("\n")
      }
      if (keywords.contains("MIT")) {
        require(year2.isDefined, "MIT keyword requires specifying two years")
        builder.append("This model was developed at the MIT Media Lab using CM StarLogo.  ")
        builder.append("See Resnick, M. (1994) \"Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds.\"  ")
        builder.append("Cambridge, MA: MIT Press.  Adapted to StarLogoT, " + year + ", ")
        builder.append("as part of the Connected Mathematics Project.\n\n")
      }
      if (keywords.contains("Wilensky")) {
        require(year2.isDefined, "Wilensky keyword requires specifying two years")
        builder.append("This model was developed at the MIT Media Lab using CM StarLogo.  ")
        builder.append("See Wilensky, U. (1993). Thesis - Connected Mathematics: Building Concrete Relationships with Mathematical Knowledge. ")
        builder.append("Adapted to StarLogoT, " + year + ", as part of the Connected Mathematics Project.  ")
        builder.append("Adapted to NetLogo, " + year2.get + ", as part of the Participatory Simulations Project.\n\n")
      }
      if (year2.isDefined) {
        require(!keywords.contains("MAC"),
          "the MAC keyword is not supported for converted StarLogoT models")
        if (year2.get <= 2004) {
          builder.append("This model was converted to NetLogo as part of the projects: ")
          builder.append("PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING ")
          builder.append("IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. ")
          builder.append("The project gratefully acknowledges the support of the ")
          builder.append("National Science Foundation (REPP & ROLE programs) -- ")
          builder.append("grant numbers REC #9814682 and REC-0126227. ")
        }
        builder.append("Converted from StarLogoT to NetLogo, " + year2.get + ".\n")
        builder.append("\n")
      }
      if (keywords.contains("NIELS")) {
        builder.append("To use this model for academic or commercial research, please ")
        builder.append("contact Pratim Sengupta at <pratim.sengupta@vanderbilt.edu> or Uri ")
        builder.append("Wilensky at <uri@northwestern.edu> for a mutual agreement prior to usage.\n\n")
      }
    }
    Info.clean(builder.toString)
  }
}

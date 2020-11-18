package org.nlogo.models

import java.net.ConnectException
import java.util.concurrent.TimeoutException

import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.concurrent.duration.DurationInt
import scala.collection.JavaConverters._
import scala.util.Try

import com.vladsch.flexmark.Extension
import com.vladsch.flexmark.ast.{ AutoLink, Document, Link, NodeVisitor, VisitHandler, Visitor }
import com.vladsch.flexmark.parser.{ Parser, ParserEmulationProfile }
import com.vladsch.flexmark.util.options.MutableDataSet
import com.vladsch.flexmark.ext.autolink.AutolinkExtension

import org.apache.commons.validator.routines.UrlValidator
import org.apache.commons.validator.routines.UrlValidator.ALLOW_2_SLASHES
import org.nlogo.api.Version
import org.nlogo.core.Model
import org.scalatest.BeforeAndAfterAll
import org.scalatest.FunSuite
import org.scalatest.concurrent.ScalaFutures

import org.asynchttpclient.{ DefaultAsyncHttpClient, DefaultAsyncHttpClientConfig, Response }

class InfoTabUrlTests extends FunSuite with ScalaFutures with BeforeAndAfterAll {

  private val parserBuilder = {
    val options = new MutableDataSet()
    options.setFrom(ParserEmulationProfile.PEGDOWN)
    val extensions = new java.util.ArrayList[Extension]()
    extensions.add(AutolinkExtension.create())
    options.set(Parser.EXTENSIONS, extensions)
    Parser.builder(options)
  }

  def linksInMarkdown(md: String): Seq[String] = {
    // use flexmark to grab the links, since that is
    // what is used to generate the info tab anyway
    val links = Seq.newBuilder[String]

    val parser = parserBuilder.build()
    val doc = parser.parse(md).asInstanceOf[Document]

    val linkVisitor = new Visitor[Link] {
      override def visit(l: Link): Unit = {
        links += l.getUrl.toString
      }
    }
    val linkRefVisitor = new Visitor[AutoLink] {
      override def visit(l: AutoLink): Unit = {
        links += l.getText.toString
      }
    }
    val visitHandler = new VisitHandler[Link](classOf[Link], linkVisitor)
    val autoLinkHandler = new VisitHandler[AutoLink](classOf[AutoLink], linkRefVisitor)
    val theVisitor = new NodeVisitor(visitHandler, autoLinkHandler)
    theVisitor.visit(doc)
    links.result()
  }

  val links: Map[String, Iterable[Model]] = libraryModels
    .filter(_.is3D == Version.is3D)
    .flatMap(m => linksInMarkdown(m.info).map(_ -> m)) // (link, model) pairs
    .groupBy(_._1) // group by links
    .mapValues(_.unzip._2) // keep only models in the map's values

  val builder = new DefaultAsyncHttpClientConfig.Builder()
  val client = new DefaultAsyncHttpClient(builder.build())
  val urlValidator = new UrlValidator(ALLOW_2_SLASHES)

  if (onLocal) {
    /* Only run the URL tests locally: they take a long time to run on Jenkins
     * and are an endless source of false positives (i.e., temporary failures),
     * lowering ones sensitivity to _actual_ failures. My hope is that keeping
     * the tests running locally will be enough to catch actual URL problems.
     * NP 2016-07-20.
     */
    test("URLs used in info tabs should be valid") {
      val failures = for {
        (link, models) <- links.par
        if link.startsWith("http")
        duration = 20.seconds
        failure <- Try(Await.result(request(link), duration))
          .getOrElse {
            // tolerate time outs from the CCL server
            if (link.contains("://ccl")) None
            else Some(s"Timed out after ${duration}!")
          }
        message = (failure + "\nUsed in:\n" +
          models.map(_.quotedPath).mkString("\n")).indent(2)
      } yield link + "\n" + message
      if (failures.nonEmpty) fail(failures.mkString("\n"))
    }
  }

  val exceptions: Map[Int, Seq[String]] = Map(
    301 -> Seq(
      "https://edrl.berkeley.edu/design/",
      "https://www.nature.com/articles/nature20801",
      "https://www.jstor.org/stable/2224214",
      "https://www.jstor.org/stable/27858114",
      "http://www.pixar.com/companyinfo/research/pbm2001/",
      "https://amaral.northwestern.edu/media/publication_pdfs/Guimera-2005-Science-308-697.pdf",
      "https://www.arduino.cc/en/software"
    ),
    403 -> Seq(
    ),
    429 -> Seq(
      "https://www.youtube.com/watch"
   )
  )

  def redirectTolerated(link: String, response: Response) =
    Set(302, 207).contains(response.getStatusCode) ||
      (response.getHeader("Location") match {
        case "/"            => true
        case l if l == link => true
        case _              => false
      })

  def request(
    link: String,
    timeout: Int = 1000): Future[Option[String]] = {
      def success = Future.successful(None)
      def failure(msg: String) = Future.successful(Option(msg))

      if (!urlValidator.isValid(link)) failure("Invalid URL!") else {
        Future {
          val future = client.prepareGet(link).execute()
          future.get(timeout, java.util.concurrent.TimeUnit.MILLISECONDS)
        }.flatMap { response =>
          response.getStatusCode match {
            case sc if sc >= 200 && sc < 300 =>
              success
            case sc if sc >= 300 && sc < 400 && redirectTolerated(link, response) =>
              success
            case sc if sc >= 500 && sc < 600 =>
              request(link, timeout)
            case sc if exceptions.get(sc).filter(_.exists(link startsWith _)).isDefined =>
              success
            case sc => failure(
              "Got response status code " + sc + ". Headers:\n" +
              response.getHeaders.asScala.mkString("\n")
            )
          }
        }.recoverWith {
          case e: ConnectException => request(link, timeout * 2)
          case e: TimeoutException => request(link, timeout * 2)
        }
      }
  }

  override def afterAll(): Unit = client.close()
}

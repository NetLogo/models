package org.nlogo.models

import java.net.ConnectException
import java.util.concurrent.TimeoutException

import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.concurrent.duration.DurationInt
import scala.collection.JavaConverters._
import scala.util.Try

import org.apache.commons.validator.routines.UrlValidator
import org.apache.commons.validator.routines.UrlValidator.ALLOW_2_SLASHES
import org.nlogo.api.Version
import org.nlogo.core.Model
import org.pegdown.Extensions.AUTOLINKS
import org.pegdown.LinkRenderer
import org.pegdown.PegDownProcessor
import org.pegdown.ToHtmlSerializer
import org.scalatest.BeforeAndAfterAll
import org.scalatest.FunSuite
import org.scalatest.concurrent.ScalaFutures

import org.asynchttpclient.{ DefaultAsyncHttpClient, DefaultAsyncHttpClientConfig, Response }

class InfoTabUrlTests extends FunSuite with ScalaFutures with BeforeAndAfterAll {

  def linksInMarkdown(md: String): Seq[String] = {
    // use pegdown to grab the links, since that is
    // what is used to generate the info tab anyway
    val links = Seq.newBuilder[String]
    val astRoot = new PegDownProcessor(AUTOLINKS).parseMarkdown(md.toCharArray)
    val serializer = new ToHtmlSerializer(new LinkRenderer()) {
      override def printLink(rendering: LinkRenderer.Rendering): Unit = {
        links += rendering.href
      }
    }
    serializer.toHtml(astRoot)
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

  if (!onTravis) {
    /* Only run the URL tests locally: they take a long time to run on Travis
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
      "http://www.the-scientist.com/?articles.view/articleNo/13750/title/Why-Leaves-Turn-Color-in-the-Fall/",
      "https://www.wolframscience.com/nksonline/page-331"
    ),
    403 -> Seq(
      "http://www.ncbi.nlm.nih.gov/pmc/articles/PMC128592/",
      "http://www.red3d.com/cwr/boids/"
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

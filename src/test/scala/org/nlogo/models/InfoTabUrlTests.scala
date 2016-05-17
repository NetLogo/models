package org.nlogo.models

import java.net.ConnectException
import java.util.concurrent.TimeoutException

import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.concurrent.duration.DurationInt
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

import com.ning.http.client.AsyncHttpClientConfig

import play.api.libs.ws.WSRequestHolder
import play.api.libs.ws.WSResponse
import play.api.libs.ws.ning.NingWSClient

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

  val builder = new AsyncHttpClientConfig.Builder()
  val client = new NingWSClient(builder.build())
  val urlValidator = new UrlValidator(ALLOW_2_SLASHES)

  val head = (_: WSRequestHolder).head()
  val get = (_: WSRequestHolder).get()

  test("URLs used in info tabs should be valid") {
    val failures = for {
      (link, models) <- links.par
      if link.startsWith("http")
      duration = 60.seconds
      failure <- Try(Await.result(request(link, head), duration))
        .getOrElse(Some(s"Timed out after ${duration}!"))
      message = (failure + "\nUsed in:\n" +
        models.map(_.quotedPath).mkString("\n")).indent(2)
    } yield link + "\n" + message
    if (failures.nonEmpty) fail(failures.mkString("\n"))
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

  def redirectTolerated(link: String, response: WSResponse) =
    Set(302, 207).contains(response.status) ||
      (response.header("Location") match {
        case Some("/")            => true
        case Some(l) if l == link => true
        case _                    => false
      })

  def request(
    link: String,
    method: WSRequestHolder => Future[WSResponse],
    timeout: Int = 1000): Future[Option[String]] = {
    def success = Future.successful(None)
    def failure(msg: String) = Future.successful(Option(msg))
    if (!urlValidator.isValid(link)) failure("Invalid URL!") else {
      val requestHolder = client.url(link).withRequestTimeout(timeout)
      method(requestHolder).flatMap { response =>
        response.status match {
          case sc if sc >= 200 && sc < 300 =>
            success
          case sc if sc >= 300 && sc < 400 && redirectTolerated(link, response) =>
            success
          case sc if (sc == 403 || sc == 404) && method == head =>
            request(link, get) // sometimes HEAD is forbidden, retry with a GET
          case sc if sc >= 500 && sc < 600 =>
            request(link, method)
          case sc if exceptions.get(sc).filter(_.exists(link startsWith _)).isDefined =>
            success
          case sc => failure(
            "Got response status code " + sc + ". Headers:\n" +
              response.allHeaders.mkString("\n")
          )
        }
      }.recoverWith {
        case e: ConnectException => request(link, method, timeout * 2)
        case e: TimeoutException => request(link, method, timeout * 2)
      }
    }
  }

  override def afterAll(): Unit = client.close()
}

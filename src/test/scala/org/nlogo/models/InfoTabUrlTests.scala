package org.nlogo.models

import java.net.ConnectException
import java.util.concurrent.TimeoutException

import scala.Left
import scala.Right
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

import org.apache.commons.validator.routines.UrlValidator
import org.apache.commons.validator.routines.UrlValidator.ALLOW_2_SLASHES
import org.pegdown.Extensions.AUTOLINKS
import org.pegdown.LinkRenderer
import org.pegdown.PegDownProcessor
import org.pegdown.ToHtmlSerializer
import org.scalatest.BeforeAndAfterAll
import org.scalatest.FunSuite
import org.scalatest.concurrent.ScalaFutures
import org.scalatest.exceptions.TestFailedException
import org.scalatest.time.Seconds
import org.scalatest.time.Span

import com.ning.http.client.AsyncHttpClientConfig

import Model.models
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

  val links: Map[String, Iterable[Model]] = models
    .flatMap(m => linksInMarkdown(m.info).map(_ -> m)) // (link, model) pairs
    .groupBy(_._1) // group by links
    .mapValues(_.unzip._2) // keep only models in the map's values
  val builder = new AsyncHttpClientConfig.Builder()
  val client = new NingWSClient(builder.build())
  val urlValidator = new UrlValidator(ALLOW_2_SLASHES)

  val head = (_: WSRequestHolder).head()
  val get = (_: WSRequestHolder).get()

  for {
    (link, models) <- links
    if !link.startsWith("mailto")
    clue = "Used in: " + models.map(_.quotedPath).mkString("  \n  ", "  \n  ", "\n")
  } {
    test(link) {
      assert(urlValidator.isValid(link), clue)
      try whenReady(request(link, head), timeout(Span(90, Seconds))) {
        case Right(optMsg) => optMsg.foreach(info(_))
        case Left(msg) => fail(msg)
      }
      catch {
        case e: TestFailedException =>
          info(clue)
          throw e
      }
    }
  }

  // Some URLs get redirect when tried from here but are
  // OK when used in browser. We make exception for those.
  val acceptRedirectFrom: Set[String] = Set(
    "http://www.the-scientist.com/?articles.view/articleNo/13750/title/Why-Leaves-Turn-Color-in-the-Fall/",
    "http://www.jstor.org/stable/2224214",
    "https://www.wolframscience.com/nksonline/page-331"
  )

  def request(
    link: String,
    method: WSRequestHolder => Future[WSResponse]): Future[Either[String, Option[String]]] = {
    def right(msg: String = null) = Future.successful(Right(Option(msg)))
    def left(msg: String) = Future.successful(Left(msg))
    val requestHolder = client.url(link).withRequestTimeout(5000)
    method(requestHolder).flatMap { response =>
      response.status match {
        case 403 if method == head =>
          request(link, get) // sometimes HEAD is forbidden, retry with a GET
        case sc if sc >= 200 && sc < 300 =>
          right() // OK
        case sc if sc >= 300 && sc < 400 =>
          val location = response.header("Location").getOrElse("no location!")
          val msg = "Got redirect " + sc + " => " + location
          location match {
            case "/" =>
              right(msg + " (redirect to root tolerated)")
            case l if l == link =>
              right(msg + " (redirect to same URL tolerated)")
            case _ if acceptRedirectFrom.contains(link) =>
              right(msg + " (tolerated exception)")
            case _ =>
              left(msg)
          }
        case sc if sc >= 500 && sc < 600 =>
          request(link, method)
        case sc =>
          left("Got response status code " + sc)
      }
    }.recoverWith {
      case e: ConnectException => request(link, method)
      case e: TimeoutException => request(link, method)
    }
  }

  override def afterAll(): Unit = client.close()
}

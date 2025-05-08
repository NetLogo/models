package org.nlogo.models

import java.awt.{ Dimension, Font, Rectangle }
import java.io.File
import java.lang.RuntimeException
import java.util.Date

import org.jfree.chart.{ ChartFactory, JFreeChart }
import org.jfree.data.category.DefaultCategoryDataset
import org.jfree.chart.labels.{ ItemLabelAnchor, ItemLabelPosition, StandardCategoryItemLabelGenerator }
import org.jfree.chart.plot.PlotOrientation
import org.jfree.chart.renderer.category.BarRenderer
import org.jfree.chart.title.TextTitle
import org.jfree.graphics2d.svg.SVGGraphics2D
import org.jfree.graphics2d.svg.SVGUtils
import org.jfree.ui.TextAnchor

object Stats {

  def exportPrimitivesUsagePlot(): Unit = {

    val data = new DefaultCategoryDataset

    libraryModels.flatMap { model =>
      try {
        new Tokens(model).primitiveTokenNames.distinct.map(_ -> model)
      } catch {
        case e: RuntimeException =>
          Console.err.println(model.file.getPath)
          e.printStackTrace()
          Seq()
      }
    }.groupBy(_._1).view.mapValues(_.size).toSeq.sortBy(t => (0 - t._2, t._1)).foreach {
      case (name, count) => data.addValue(count, "", name)
    }

    val chart = ChartFactory.createBarChart("Usage of primitives in the Models Library", null, "Number of models",
                                            data, PlotOrientation.HORIZONTAL, false, false, false)
    chart.addSubtitle(new TextTitle(new Date().toString))

    val renderer = new BarRenderer
    renderer.setShadowVisible(false)
    renderer.setDrawBarOutline(true)
    renderer.setBaseItemLabelGenerator(new StandardCategoryItemLabelGenerator)
    renderer.setBaseItemLabelsVisible(true)
    renderer.setBasePositiveItemLabelPosition(new ItemLabelPosition(ItemLabelAnchor.OUTSIDE3, TextAnchor.CENTER_LEFT))

    val plot = chart.getCategoryPlot
    plot.setRenderer(renderer)
    plot.getDomainAxis.setTickLabelFont(new Font("Monospaced", Font.PLAIN, 12))
    plot.getDomainAxis.setUpperMargin(0.005)
    plot.getDomainAxis.setLowerMargin(0.005)
    saveAsSVG(chart, "test/stats/usage_of_primitives.svg", 1000, 4500)
  }

  // shouldn't be needed anymore once
  // https://github.com/wookietreiber/scala-chart/issues/12
  // makes it into a scala-chart release
  def saveAsSVG(chart: JFreeChart, file: String, width: Int, height: Int): Unit = {
    val g2 = new SVGGraphics2D(width, height)
    chart.draw(g2, new Rectangle(new Dimension(width, height)))
    val svg = g2.getSVGElement
    g2.dispose()
    SVGUtils.writeToSVG(new File(file), svg)
  }

  def main(args: Array[String]): Unit = exportPrimitivesUsagePlot()
}

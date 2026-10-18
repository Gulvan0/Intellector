package client.ui.profile;

import client.datatypes.player.RatingPoint;
import client.formatters.ProfileFormatters;
import client.ui.common.WidthObserver;
import haxe.ui.components.Label;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxefolio.ElementShadow;
import js.Browser;
import js.html.Element;
import morestd.Detachable;

/**
    A rating's history as a line over time, with gridlines at round ratings, the first, middle and
    last dates under it, and the date and rating of the point nearest the pointer in a tooltip.
**/
class RatingChart extends HBox
{
    private static inline final SVG_NAMESPACE:String = "http://www.w3.org/2000/svg";
    private static inline final PLOT_HEIGHT:Float = 110;
    private static inline final AXIS_WIDTH:Float = 30;
    private static inline final DATE_LABEL_WIDTH:Float = 90;
    private static inline final TICK_LABEL_HALF_HEIGHT:Float = 7;
    private static inline final MARKER_RADIUS:Float = 5;
    private static inline final TOOLTIP_GAP:Float = 12;
    private static inline final TOOLTIP_MIN_SHARE:Float = 0.18;
    private static inline final TOOLTIP_WIDTH:Float = 92;
    private static inline final TOOLTIP_HEIGHT:Float = 42;
    private static inline final MONTH_LABELS_MIN_SPAN_MS:Float = 60 * 24 * 60 * 60 * 1000.0;

    private final axis:Absolute;
    private final plot:Absolute;
    private final dateRow:Absolute;
    private final svg:Element;
    private final hoverLine:Box;
    private final marker:Box;
    private final hoverTooltip:VBox;
    private final tooltipDateLabel:Label;
    private final tooltipRatingLabel:Label;
    private final widthHandle:Detachable;

    private var points:Array<RatingPoint> = [];
    private var low:Float = 0;
    private var high:Float = 1;
    private var plotWidth:Float = 0;

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.RATING_CHART);

        axis = new Absolute();
        axis.width = AXIS_WIDTH;
        axis.height = PLOT_HEIGHT;
        axis.addClass(StyleClass.RATING_CHART_LAYER);
        addComponent(axis);

        var plotColumn:VBox = new VBox();
        plotColumn.percentWidth = 100;
        plotColumn.addClass(StyleClass.RATING_CHART_COLUMN);
        addComponent(plotColumn);

        plot = new Absolute();
        plot.percentWidth = 100;
        plot.height = PLOT_HEIGHT;
        plot.addClass(StyleClass.RATING_CHART_LAYER);
        plot.registerEvent(MouseEvent.MOUSE_MOVE, onPointerMove);
        plot.registerEvent(MouseEvent.MOUSE_OUT, _ -> hideHover());
        plotColumn.addComponent(plot);

        svg = Browser.document.createElementNS(SVG_NAMESPACE, "svg");
        svg.setAttribute("viewBox", "0 0 1000 1000");
        svg.setAttribute("preserveAspectRatio", "none");
        svg.setAttribute("style", "position: absolute; left: 0; top: 0; width: 100%; height: 100%; overflow: visible; pointer-events: none;");
        plot.element.appendChild(svg);

        hoverLine = new Box();
        hoverLine.addClass(StyleClass.RATING_CHART_HOVER_LINE);
        hoverLine.height = PLOT_HEIGHT;
        hoverLine.hidden = true;
        plot.addComponent(hoverLine);

        marker = new Box();
        marker.addClass(StyleClass.RATING_CHART_MARKER);
        marker.hidden = true;
        plot.addComponent(marker);

        hoverTooltip = new VBox();
        hoverTooltip.addClass(StyleClass.RATING_CHART_TOOLTIP);
        hoverTooltip.width = TOOLTIP_WIDTH;
        ElementShadow.apply(hoverTooltip.element, StyleVars.FILTER_POPUP_SHADOW);
        hoverTooltip.hidden = true;
        plot.addComponent(hoverTooltip);

        tooltipDateLabel = new Label();
        tooltipDateLabel.addClass(StyleClass.PROFILE_SMALL_MUTED);
        hoverTooltip.addComponent(tooltipDateLabel);

        tooltipRatingLabel = new Label();
        tooltipRatingLabel.addClass(StyleClass.PROFILE_MONO);
        hoverTooltip.addComponent(tooltipRatingLabel);

        dateRow = new Absolute();
        dateRow.percentWidth = 100;
        dateRow.addClass(StyleClass.RATING_CHART_DATES);
        plotColumn.addComponent(dateRow);

        widthHandle = WidthObserver.observe(plot, width -> {
            plotWidth = width;
            renderDates();
        });
    }

    /** The rating each day ended at, one point per local day at its midnight, given `points` in time order **/
    public static function dailyPoints(points:Array<RatingPoint>):Array<RatingPoint>
    {
        var daily:Array<RatingPoint> = [];
        for (point in points)
        {
            var date:Date = Date.fromTime(point.atMs);
            var dayPoint:RatingPoint = new RatingPoint(new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0).getTime(), point.elo);
            if (daily.length > 0 && daily[daily.length - 1].atMs == dayPoint.atMs)
                daily[daily.length - 1] = dayPoint;
            else
                daily.push(dayPoint);
        }
        return daily;
    }

    /** Needs at least two points **/
    public function setPoints(points:Array<RatingPoint>):Void
    {
        this.points = points;
        hideHover();

        var lowest:Float = Math.POSITIVE_INFINITY;
        var highest:Float = Math.NEGATIVE_INFINITY;
        for (point in points)
        {
            lowest = Math.min(lowest, point.elo);
            highest = Math.max(highest, point.elo);
        }

        var range:Float = highest - lowest;
        var step:Float = range <= 120 ? 25 : range <= 300 ? 50 : 100;
        low = Math.floor((lowest - step * 0.3) / step) * step;
        high = Math.ceil((highest + step * 0.3) / step) * step;

        while (svg.firstChild != null)
            svg.removeChild(svg.firstChild);
        axis.removeAllComponents();

        var tick:Float = low;
        while (tick <= high)
        {
            var y:Float = yShare(tick);
            var gridline:Element = Browser.document.createElementNS(SVG_NAMESPACE, "line");
            gridline.setAttribute("x1", "0");
            gridline.setAttribute("x2", "1000");
            gridline.setAttribute("y1", Std.string(y * 1000));
            gridline.setAttribute("y2", Std.string(y * 1000));
            gridline.setAttribute("stroke", StyleVars.RATING_CHART_GRID);
            gridline.setAttribute("stroke-width", "1");
            gridline.setAttribute("vector-effect", "non-scaling-stroke");
            svg.appendChild(gridline);

            var tickLabel:Label = new Label();
            tickLabel.text = Std.string(Std.int(tick));
            tickLabel.width = AXIS_WIDTH;
            tickLabel.addClass(StyleClass.RATING_CHART_TICK);
            tickLabel.top = y * PLOT_HEIGHT - TICK_LABEL_HALF_HEIGHT;
            axis.addComponent(tickLabel);

            tick += step;
        }

        var line:Element = Browser.document.createElementNS(SVG_NAMESPACE, "polyline");
        line.setAttribute("points", [for (i in 0...points.length) '${xShare(i) * 1000},${yShare(points[i].elo) * 1000}'].join(" "));
        line.setAttribute("fill", "none");
        line.setAttribute("stroke", StyleVars.RATING_CHART_LINE);
        line.setAttribute("stroke-width", "2");
        line.setAttribute("stroke-linejoin", "round");
        line.setAttribute("stroke-linecap", "round");
        line.setAttribute("vector-effect", "non-scaling-stroke");
        svg.appendChild(line);

        renderDates();
    }

    public function dispose():Void
    {
        widthHandle.detach();
    }

    private function renderDates():Void
    {
        dateRow.removeAllComponents();
        if (points.length < 2 || plotWidth <= 0)
            return;

        var firstMs:Float = points[0].atMs;
        var lastMs:Float = points[points.length - 1].atMs;
        for (i in 0...3)
        {
            var dateLabel:Label = new Label();
            var atMs:Float = firstMs + (lastMs - firstMs) * i / 2;
            dateLabel.text = lastMs - firstMs >= MONTH_LABELS_MIN_SPAN_MS ? ProfileFormatters.monthAndYear(atMs) : ProfileFormatters.shortDateWithYear(atMs);
            dateLabel.width = DATE_LABEL_WIDTH;
            dateLabel.addClass(StyleClass.RATING_CHART_DATE);
            dateLabel.addClass(switch i {
                case 0: StyleClass.RATING_CHART_DATE_START;
                case 1: StyleClass.RATING_CHART_DATE_MIDDLE;
                default: StyleClass.RATING_CHART_DATE_END;
            });
            dateLabel.left = switch i {
                case 0: 0;
                case 1: plotWidth / 2 - DATE_LABEL_WIDTH / 2;
                default: plotWidth - DATE_LABEL_WIDTH;
            };
            dateRow.addComponent(dateLabel);
        }
    }

    private function onPointerMove(event:MouseEvent):Void
    {
        if (points.length < 2 || plotWidth <= 0)
            return;

        var pointerShare:Float = event.localX / plotWidth;
        var nearest:Int = 0;
        for (i in 1...points.length)
            if (Math.abs(xShare(i) - pointerShare) <= Math.abs(xShare(nearest) - pointerShare))
                nearest = i;
        showHover(nearest);
    }

    private function showHover(index:Int):Void
    {
        var point:RatingPoint = points[index];
        var x:Float = xShare(index) * plotWidth;
        var yShareValue:Float = yShare(point.elo);
        var y:Float = yShareValue * PLOT_HEIGHT;

        hoverLine.left = x;
        hoverLine.hidden = false;
        marker.left = x - MARKER_RADIUS;
        marker.top = y - MARKER_RADIUS;
        marker.hidden = false;

        tooltipDateLabel.text = ProfileFormatters.shortDateWithYear(point.atMs);
        tooltipRatingLabel.text = Std.string(point.elo);
        hoverTooltip.hidden = false;

        var centre:Float = Math.min(Math.max(x, plotWidth * TOOLTIP_MIN_SHARE), plotWidth * (1 - TOOLTIP_MIN_SHARE));
        hoverTooltip.left = centre - TOOLTIP_WIDTH / 2;
        hoverTooltip.top = yShareValue < 0.45 ? y + TOOLTIP_GAP : y - TOOLTIP_GAP - TOOLTIP_HEIGHT;
    }

    private function hideHover():Void
    {
        hoverLine.hidden = true;
        marker.hidden = true;
        hoverTooltip.hidden = true;
    }

    /** Where the point lies between the first and the last point's dates; evenly spaced if those coincide **/
    private function xShare(index:Int):Float
    {
        if (points.length < 2)
            return 0;

        var firstMs:Float = points[0].atMs;
        var spanMs:Float = points[points.length - 1].atMs - firstMs;
        return spanMs > 0 ? (points[index].atMs - firstMs) / spanMs : index / (points.length - 1);
    }

    private function yShare(elo:Float):Float
    {
        return 1 - (elo - low) / (high - low);
    }
}

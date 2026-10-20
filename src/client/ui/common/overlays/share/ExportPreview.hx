package client.ui.common.overlays.share;

import client.ui.common.board.export.BoardRaster;
import client.ui.common.board.export.BoardRaster.BoardPicture;
import haxe.ui.Toolkit;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import morestd.Detachable;

/**
    What an export will look like: the picture drawn by the exporter itself, scaled to fit the area
    (contain) and centred, with a 1 px outline on its bounds. A transparent picture shows over a
    checkerboard, inside the picture only. Redrawing is asynchronous; only the latest request shows.
**/
class ExportPreview extends Box
{
    private final holder:Component;
    private final canvas:CanvasElement;
    private final widthHandle:Detachable;
    private var areaWidth:Float = 0;
    private var picture:Null<BoardPicture> = null;
    private var exportWidth:Int = 1;
    private var exportHeight:Int = 1;
    private var requestNumber:Int = 0;

    /** `areaHeight` is fixed; the width follows the container **/
    public function new(areaHeight:Int)
    {
        super();

        this.percentWidth = 100;
        this.height = areaHeight;
        this.addClass(StyleClass.SHARE_PREVIEW);

        holder = new Component();
        holder.horizontalAlign = "center";
        holder.verticalAlign = "center";
        holder.addClass(StyleClass.SHARE_PREVIEW_IMAGE);
        this.addComponent(holder);

        canvas = Browser.document.createCanvasElement();
        canvas.style.display = "block";
        canvas.style.width = "100%";
        canvas.style.height = "100%";
        holder.element.appendChild(canvas);

        widthHandle = WidthObserver.observe(this, width -> {
            areaWidth = width;
            redraw();
        });
    }

    /** Shows `picture` as an `exportWidth`x`exportHeight` export would draw it **/
    public function display(picture:BoardPicture, exportWidth:Int, exportHeight:Int):Void
    {
        this.picture = picture;
        this.exportWidth = exportWidth;
        this.exportHeight = exportHeight;
        redraw();
    }

    public function dispose():Void
    {
        widthHandle.detach();
        requestNumber++;
    }

    private function redraw():Void
    {
        if (picture == null || areaWidth <= 0)
            return;

        // the outline is drawn on the picture's edge, inside the area
        var scale:Float = Math.min((areaWidth - 2) / exportWidth, (this.height - 2) / exportHeight);
        var shownWidth:Int = Std.int(Math.max(1, Math.round(exportWidth * scale)));
        var shownHeight:Int = Std.int(Math.max(1, Math.round(exportHeight * scale)));
        var pixelRatio:Float = Browser.window.devicePixelRatio * Toolkit.scaleX;
        var pixelWidth:Int = Std.int(Math.max(1, Math.round(shownWidth * pixelRatio)));
        var pixelHeight:Int = Std.int(Math.max(1, Math.round(shownHeight * pixelRatio)));
        var transparent:Bool = picture.background == null;
        var request:Int = ++requestNumber;

        BoardRaster.draw(picture, pixelWidth, pixelHeight, drawn -> {
            if (request != requestNumber)
                return;

            holder.width = shownWidth + 2;
            holder.height = shownHeight + 2;

            canvas.width = pixelWidth;
            canvas.height = pixelHeight;
            var context:CanvasRenderingContext2D = canvas.getContext2d();
            context.clearRect(0, 0, pixelWidth, pixelHeight);
            if (transparent)
                drawCheckerboard(context, pixelWidth, pixelHeight, pixelRatio);
            context.drawImage(drawn, 0, 0);
        });
    }

    private static function drawCheckerboard(context:CanvasRenderingContext2D, width:Int, height:Int, pixelRatio:Float):Void
    {
        var cell:Float = StyleVars.SHARE_PREVIEW_CHECKER_CELL * pixelRatio;

        context.fillStyle = StyleVars.SHARE_PREVIEW_CHECKER_LIGHT;
        context.fillRect(0, 0, width, height);
        context.fillStyle = StyleVars.SHARE_PREVIEW_CHECKER_DARK;

        var row:Int = 0;
        while (row * cell < height)
        {
            var column:Int = row % 2;
            while (column * cell < width)
            {
                context.fillRect(column * cell, row * cell, cell, cell);
                column += 2;
            }
            row++;
        }
    }
}

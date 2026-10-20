package client.ui.common.board.export;

import client.ui.Assets;
import client.ui.common.board.BoardPalette;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.HexTints;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;
import js.Browser;
import js.html.Blob;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Element;
import js.html.ImageElement;
import js.html.URL;
import js.html.XMLSerializer;
import js.lib.Promise;

typedef BoardPicture = {
    position:Position,
    orientation:PieceColor,
    /** Tinted as on the board; null for no tint **/
    lastMove:Null<RawPly>,
    /** Row numbers and file letters **/
    labels:Bool,
    /** `#rrggbb`; null for a transparent background **/
    background:Null<String>
}

/**
    Board pictures of any size, for the exports and their previews alike: the board's own
    `BoardSurface` drawing, fitted (contain) into the picture with a margin, over the background.
    The SVG is rasterized by the browser as an isolated image, so the pieces it references are
    inlined first. Drawing is asynchronous; callers that redraw often ignore stale results.
**/
class BoardRaster
{
    private static inline final MARGIN_SHARE:Float = 0.03; // of the picture's shorter side, around the board
    private static inline final LABEL_FONT_FAMILY:String = "sans-serif"; // what the board on the page inherits
    private static inline final LIGHT_BACKGROUND_LABEL:String = "#6d6152";
    private static inline final DARK_BACKGROUND_LABEL:String = "#e9e3d9";

    private static var inlinedImages:Null<Map<String, String>> = null;
    private static var waitingForImages:Array<Map<String, String>->Void> = [];

    /** Height over width of a picture the board fills, margins included **/
    public static function naturalRatio(labels:Bool):Float
    {
        var boardRatio:Float = BoardSurface.aspectRatioOf(labels ? ALL : NONE);
        var margins:Float = 2 * MARGIN_SHARE;

        // the shorter side is the height for a wide board, the width for a tall one
        return boardRatio >= 1 ? 1 / ((1 - margins) * boardRatio + margins) : (1 - margins) / boardRatio + margins;
    }

    /** Draws `picture` `width`x`height`; `onDrawn` gets a canvas of that size **/
    public static function draw(picture:BoardPicture, width:Int, height:Int, onDrawn:CanvasElement->Void):Void
    {
        whenImagesInlined(images -> {
            var url:String = URL.createObjectURL(new Blob([markup(picture, width, height, images)], {type: "image/svg+xml"}));
            var image:ImageElement = Browser.document.createImageElement();

            image.onload = () -> {
                URL.revokeObjectURL(url);

                var canvas:CanvasElement = Browser.document.createCanvasElement();
                canvas.width = width;
                canvas.height = height;
                var context:CanvasRenderingContext2D = canvas.getContext2d();
                context.drawImage(image, 0, 0, width, height);
                onDrawn(canvas);
            };
            image.onerror = () -> URL.revokeObjectURL(url);
            image.src = url;
        });
    }

    private static function markup(picture:BoardPicture, width:Int, height:Int, images:Map<String, String>):String
    {
        var palette:BoardPalette = BoardPalette.DEFAULT.withFileLetter(labelColor(picture.background));
        var surface:BoardSurface = new BoardSurface(picture.position, picture.orientation, picture.labels ? ALL : NONE, palette);
        var tints:HexTints = new HexTints(surface.grid, palette);
        if (picture.lastMove != null)
            tints.set(LastMove, [picture.lastMove.from, picture.lastMove.to]);

        var boardSvg:Element = surface.element.querySelector("svg");
        for (image in boardSvg.querySelectorAll("image"))
        {
            var element:Element = cast image;
            var href:Null<String> = element.getAttribute("href");
            if (href != null && images.exists(href))
                element.setAttribute("href", images.get(href));
        }

        var boardRatio:Float = BoardSurface.aspectRatioOf(picture.labels ? ALL : NONE);
        var margin:Float = MARGIN_SHARE * Math.min(width, height);
        var areaWidth:Float = width - 2 * margin;
        var areaHeight:Float = height - 2 * margin;
        var boardWidth:Float = Math.min(areaWidth, areaHeight * boardRatio);
        var boardHeight:Float = boardWidth / boardRatio;

        boardSvg.removeAttribute("style");
        boardSvg.setAttribute("x", Std.string(margin + (areaWidth - boardWidth) / 2));
        boardSvg.setAttribute("y", Std.string(margin + (areaHeight - boardHeight) / 2));
        boardSvg.setAttribute("width", Std.string(boardWidth));
        boardSvg.setAttribute("height", Std.string(boardHeight));

        var background:String = picture.background != null ? '<rect width="$width" height="$height" fill="${picture.background}"/>' : "";

        return '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">'
            + '<style>text { font-family: $LABEL_FONT_FAMILY; }</style>'
            + background
            + new XMLSerializer().serializeToString(boardSvg)
            + '</svg>';
    }

    /** File letters stand on the background, so they follow its lightness **/
    private static function labelColor(background:Null<String>):String
    {
        if (background == null)
            return LIGHT_BACKGROUND_LABEL;

        var red:Int = Std.parseInt('0x${background.substr(1, 2)}');
        var green:Int = Std.parseInt('0x${background.substr(3, 2)}');
        var blue:Int = Std.parseInt('0x${background.substr(5, 2)}');
        var lightness:Float = (0.299 * red + 0.587 * green + 0.114 * blue) / 255;

        return lightness > 0.5 ? LIGHT_BACKGROUND_LABEL : DARK_BACKGROUND_LABEL;
    }

    private static function whenImagesInlined(callback:Map<String, String>->Void):Void
    {
        if (inlinedImages != null)
        {
            callback(inlinedImages);
            return;
        }

        waitingForImages.push(callback);
        if (waitingForImages.length > 1)
            return;

        var hrefs:Array<String> = [];
        for (kind in PieceKind.createAll())
            for (color in PieceColor.createAll())
                hrefs.push(Assets.pieceImage(kind, color));

        var loads:Array<Promise<String>> = hrefs.map(href -> Browser.window.fetch(href).then(response -> response.text()));

        Promise.all(loads).then(texts -> {
            var images:Map<String, String> = [];
            for (i in 0...hrefs.length)
                images.set(hrefs[i], "data:image/svg+xml;base64," + Base64.encode(Bytes.ofString(texts[i])));
            inlinedImages = images;
            releaseWaiting(images);
        }).catchError(_ -> releaseWaiting([])); // drawn without pieces; the next draw retries
    }

    private static function releaseWaiting(images:Map<String, String>):Void
    {
        var callbacks:Array<Map<String, String>->Void> = waitingForImages;
        waitingForImages = [];
        for (waiting in callbacks)
            waiting(images);
    }
}

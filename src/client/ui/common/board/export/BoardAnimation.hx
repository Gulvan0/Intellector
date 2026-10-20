package client.ui.common.board.export;

import client.ui.common.board.export.BoardRaster.BoardPicture;
import client.utils.GifEnc;
import js.html.Blob;
import js.html.CanvasElement;
import js.html.ImageData;
import js.lib.Uint8ClampedArray;

/**
    A GIF of `frames`, each shown for the interval and the last one `LAST_FRAME_HOLD` times as long,
    looping. Encoded one frame at a time, every frame drawn asynchronously, so the page keeps
    responding; `onProgress` follows the share of frames done. The colours come from the first and
    the last frame, which between them hold every colour the board uses.
**/
class BoardAnimation
{
    private static inline final LAST_FRAME_HOLD:Int = 3;
    private static inline final MAX_COLORS:Int = 256;
    private static inline final MAX_PALETTE_SAMPLE_PIXELS:Int = 1000000;

    private final frames:Array<BoardPicture>;
    private final width:Int;
    private final height:Int;
    private final intervalMs:Int;
    private final onProgress:Float->Void;
    private final onDone:Blob->Void;
    private final encoder:GifEncoder;
    private var palette:Null<GifPalette> = null;
    private var cancelled:Bool = false;

    /** Starts encoding right away **/
    public function new(frames:Array<BoardPicture>, width:Int, height:Int, intervalMs:Int, onProgress:Float->Void, onDone:Blob->Void)
    {
        this.frames = frames;
        this.width = width;
        this.height = height;
        this.intervalMs = intervalMs;
        this.onProgress = onProgress;
        this.onDone = onDone;

        encoder = GifEnc.GIFEncoder();

        BoardRaster.draw(frames[0], width, height, first -> {
            BoardRaster.draw(frames[frames.length - 1], width, height, last -> {
                if (cancelled)
                    return;

                palette = GifEnc.quantize(paletteSample([pixels(first), pixels(last)]), MAX_COLORS);
                encodeFrame(0);
            });
        });
    }

    /** Stops encoding; nothing is reported afterwards **/
    public function cancel():Void
    {
        cancelled = true;
    }

    private function encodeFrame(index:Int):Void
    {
        BoardRaster.draw(frames[index], width, height, canvas -> {
            if (cancelled)
                return;

            var last:Bool = index == frames.length - 1;
            encoder.writeFrame(GifEnc.applyPalette(pixels(canvas), palette), width, height, {
                palette: index == 0 ? palette : null,
                delay: last ? LAST_FRAME_HOLD * intervalMs : intervalMs
            });
            onProgress((index + 1) / frames.length);

            if (!last)
            {
                encodeFrame(index + 1);
                return;
            }

            encoder.finish();
            onDone(new Blob([encoder.bytes()], {type: "image/gif"}));
        });
    }

    private function pixels(canvas:CanvasElement):Uint8ClampedArray
    {
        var data:ImageData = canvas.getContext2d().getImageData(0, 0, width, height);
        return data.data;
    }

    // every n-th pixel of each frame, so a huge picture doesn't make quantizing slow
    private function paletteSample(frameData:Array<Uint8ClampedArray>):Uint8ClampedArray
    {
        var pixelsPerFrame:Int = width * height;
        var step:Int = Std.int(Math.max(1, Math.ceil(pixelsPerFrame * frameData.length / MAX_PALETTE_SAMPLE_PIXELS)));
        var samplesPerFrame:Int = Math.ceil(pixelsPerFrame / step);
        var sample:Uint8ClampedArray = new Uint8ClampedArray(samplesPerFrame * frameData.length * 4);

        var offset:Int = 0;
        for (data in frameData)
        {
            var pixel:Int = 0;
            while (pixel < pixelsPerFrame)
            {
                for (channel in 0...4)
                    sample[offset + channel] = data[pixel * 4 + channel];
                offset += 4;
                pixel += step;
            }
        }

        return sample;
    }
}

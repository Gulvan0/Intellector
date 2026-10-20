package client.utils;

import js.lib.Uint8Array;
import js.lib.Uint8ClampedArray;

typedef GifPalette = Array<Array<Int>>;

typedef GifFrameOptions = {
    /** Required on the first frame (the global colour table); on a later one it becomes a local table **/
    ?palette:GifPalette,
    /** Milliseconds, stored in tens **/
    ?delay:Int,
    /** 0 loops forever, -1 plays once **/
    ?repeat:Int
}

extern class GifEncoder
{
    public function writeFrame(index:Uint8Array, width:Int, height:Int, ?options:GifFrameOptions):Void;
    public function finish():Void;
    public function bytes():Uint8Array;
}

/** gifenc 1.0.3, put on `window.gifenc` by `index.html` **/
@:native("gifenc")
extern class GifEnc
{
    public static function GIFEncoder():GifEncoder;

    /** Up to `maxColors` colours picked from RGBA pixels **/
    public static function quantize(rgba:Uint8ClampedArray, maxColors:Int):GifPalette;

    /** Each RGBA pixel as the index of its nearest `palette` colour **/
    public static function applyPalette(rgba:Uint8ClampedArray, palette:GifPalette):Uint8Array;
}

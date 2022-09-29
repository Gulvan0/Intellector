package;

import openfl.Lib;
import openfl.Assets;
import openfl.display.Preloader.DefaultPreloader;

class Preloader extends DefaultPreloader
{
 	public override function onInit():Void 
    {
        Assets.loadLibrary("preloader").onComplete (function (_) {
            var mc = Assets.getMovieClip("preloader:LogoPreloader");
            mc.x = (Lib.current.stage.stageWidth  )/ 2;
            mc.y = (Lib.current.stage.stageHeight ) / 2;
            addChildAt (mc,0);
        });
        
    }
}
package components;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.DisplayObject;

enum Align
{
    Left;
    Center;
    Right;
}

class Utils 
{
    public static function resizeAccordingly(obj:DisplayObject, fitWidth:Float, fitHeight:Float) 
	{
		var scale:Float = Math.min(fitWidth / obj.width, fitHeight / obj.height); 
		scale = Math.min(1, scale);
		obj.scaleX = scale;
		obj.scaleY = scale;
	}

	public static function getOffset(obj:DisplayObject):Point
	{
		var rect:Rectangle = obj.getBounds(obj);
		return new Point(rect.x, rect.y);
	}

	public static function disposeAlignedH(obj:DisplayObject, width:Float, align:Align, ?left:Float = 0, ?objWidth:Float)
	{
		if (objWidth == null)
			objWidth = obj.width;

		obj.x = switch align {
			case Left: left;
			case Center: left + (width - objWidth)/2;
			case Right: left + width - objWidth;
		}
	}

	public static function disposeAlignedV(obj:DisplayObject, height:Float, align:Align, ?top:Float = 0, ?objHeight:Float)
	{
		if (objHeight == null)
			objHeight = obj.height;
		
		obj.y = switch align {
			case Left: top;
			case Center: top + (height - objHeight)/2;
			case Right: top + height - objHeight;
		}
	}
}
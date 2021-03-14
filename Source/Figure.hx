package;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

enum FigureType
{
    Progressor;
    Aggressor;
    Dominator;
    Liberator;
    Defensor;
    Intellector;
}

enum FigureColor
{
    White;
    Black;
}

class Figure extends Sprite 
{
    public static var bitmaps:Map<FigureType, Map<FigureColor, BitmapData>>;
    public var type:FigureType;
    public var color:FigureColor;

    public function new(type:FigureType, color:FigureColor)
    {
        super();
        this.type = type;
        this.color = color;
        var bitmap = new Bitmap(bitmaps[type][color]);
        bitmap.x = -bitmap.width / 2;
        bitmap.y = -bitmap.height / 2;
        addChild (bitmap);
    }

    public static function initFigures()
    {
        bitmaps = [];
        for (fig in FigureType.createAll())
        {
            bitmaps[fig] = new Map<FigureColor, BitmapData>();
            for (col in FigureColor.createAll())
                bitmaps[fig][col] = Assets.getBitmapData(pathToImage(fig, col));
        }
    }

    public static inline function pathToImage(type:FigureType, color:FigureColor, ?icon:Bool = false):String
    {
        var filename:String = type.getName() + "_" + color.getName().toLowerCase();
        if (icon)
            return 'assets/figicons/$filename.png';
        else
            return 'assets/figures/$filename.png';
    }
}
package gfx.basic_components;

import haxe.ui.containers.HBox;

@:xml('
    <hbox width="200" height="100">
        <arp-image id="img" verticalAlign="center" />
        <autosizing-label id="lbl" verticalAlign="center" />
    </hbox>
')
class AnnotatedImage extends HBox
{
    public var spacing:Float = 10;

    public var imgPath(default, set):String = "";
    public var imgTooltip(default, set):Null<String> = null;
    public var imgAspectRatio(default, set):Null<Float> = null;
    private var actualAspectRatio:Float = 1;

    public var minFontSize:Float = 10;
    public var sizePerCharWidth:Float = 1.8;
    public var lengthGetter:Label->Int = label -> label.text.length;

    private function set_imgPath(v:String):String
    {
        imgPath = v;

        img.resource = imgPath;
        set_imgAspectRatio(imgAspectRatio);

        return v;
    }

    private function set_imgAspectRatio(v:Null<Float>):Null<Float> 
    {
        imgAspectRatio = v;

        if (imgAspectRatio != null)
            actualAspectRatio = imgAspectRatio;
        else
            actualAspectRatio = img.originalWidth / img.originalHeight;
        
        img.width = height * actualAspectRatio;
        img.height = height;

        validateComponentLayout();

        return v;
    }

    private function set_imgTooltip(v:Null<String>):Null<String>
    {
        imgTooltip = v;
        img.tooltip = imgTooltip;
        return v;
    }

    private override function validateComponentLayout() 
    {
        var b:Bool = super.validateComponentLayout();

        lbl.minFontSize = minFontSize;
        lbl.sizePerCharWidth = sizePerCharWidth;
        lbl.lengthGetter = lengthGetter;
        lbl.targetWidth = width - imageWidth - spacing;
        lbl.validateFontSize();

        customStyle = {horizontalSpacing: spacing};

        return b;
    }
}
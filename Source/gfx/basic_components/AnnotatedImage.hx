package gfx.basic_components;

import gfx.basic_components.utils.DimValue;
import haxe.ui.styles.Style;
import haxe.ui.containers.HBox;

class AnnotatedImage extends HBox
{
    public var img:ARPImage;
    public var lbl:AutosizingLabel;

    private var squareImage:Bool;

    private var spacingPerHeightUnit:Float;
    private var imageScaleFactor:Float;

    private override function validateComponentLayout() 
    {
        var b:Bool = super.validateComponentLayout();

        var spacing:Float = spacingPerHeightUnit * height;
        var newStyle:Style = customStyle.clone();
        newStyle.horizontalSpacing = spacing;
        newStyle.paddingTop = spacing;
        newStyle.paddingBottom = spacing;
        newStyle.paddingLeft = spacing;
        newStyle.paddingRight = spacing;
        customStyle = newStyle;

        if (squareImage)
            if (img.originalWidth > img.originalHeight)
                img.percentWidth = 100 * imageScaleFactor;
            else
                img.percentHeight = 100 * imageScaleFactor;

        return b;
    }

    public function new(w:DimValue, h:DimValue, imgPath:String, labelText:String, ?imgTooltip:Null<String>, ?spacingPerHeightUnit:Float = 0.16, ?imageScaleFactor:Float = 1, ?squareImage:Bool = true)
    {
        if (h == Auto)
            throw "autoHeight cannot be true for AnnotatedImage";

        super();
        this.squareImage = squareImage;
        this.spacingPerHeightUnit = spacingPerHeightUnit;
        this.imageScaleFactor = imageScaleFactor;

        assignWidth(this, w);
        assignHeight(this, h);

        img = new ARPImage();
        lbl = new AutosizingLabel();
        
        img.resource = imgPath;
        img.tooltip = imgTooltip;

        var imageStyle:Style = {};

        imageStyle.verticalAlign = "center";
        imageStyle.horizontalAlign = "center";

        if (imgTooltip != null)
        {
            imageStyle.backgroundColor = 0;
            imageStyle.backgroundOpacity = 0;
            imageStyle.pointerEvents = 'true';
        }

        img.customStyle = imageStyle;

        if (squareImage)
        {
            var sq:Square = new Square();
            sq.percentHeight = 100;
            sq.addComponent(img);
            addComponent(sq);
        }
        else
        {
            img.percentHeight = 100 * imageScaleFactor;
            addComponent(img);
        }

        if (w != Auto)
            lbl.percentWidth = 100;
        lbl.percentHeight = 100;
        lbl.text = labelText;
        lbl.align = w == Auto? Left : Center;
        addComponent(lbl);
    }
}
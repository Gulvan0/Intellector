package gfx.basic_components;

import gfx.basic_components.utils.DimValue;
import haxe.ui.styles.Style;
import haxe.ui.containers.HBox;

@:xml('
    <hbox>
        <arp-image id="img" height="100%" horizontalAlign="center" verticalAlign="center" />
        <autosizing-label id="lbl" height="100%" verticalAlign="center" />
    </hbox>
')
class AnnotatedImage extends HBox
{
    private var squareImage:Bool;
    private var spacingPerHeightUnit:Float;

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

        if (squareImage && img.originalWidth > img.originalHeight)
            img.percentHeight = 100 * img.originalHeight / img.originalWidth;

        if (img.layout != null)
            img.validateComponentLayout();

        return b;
    }

    public function new(w:DimValue, h:DimValue, imgPath:String, labelText:String, squareImage:Bool, ?imgTooltip:Null<String>, ?spacingPerHeightUnit:Float = 0.16)
    {
        super();

        if (h == Auto)
            throw "autoHeight cannot be true for AnnotatedImage";

        assignWidth(this, w);
        assignHeight(this, h);
        this.spacingPerHeightUnit = spacingPerHeightUnit;
        this.squareImage = squareImage;

        lbl.text = labelText;
        lbl.align = w == Auto? Left : Center;

        img.resource = imgPath;
        img.tooltip = imgTooltip;

        if (imgTooltip != null)
            img.customStyle = {backgroundColor: 0, backgroundOpacity: 0, pointerEvents: 'true', horizontalAlign: "center", verticalAlign: "center"};

        if (w != Auto)
            lbl.percentWidth = 100;
    }
}
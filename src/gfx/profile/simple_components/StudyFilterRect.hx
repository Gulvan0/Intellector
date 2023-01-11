package gfx.profile.simple_components;

import dict.Phrase;
import haxe.ui.events.UIEvent;
import dict.Dictionary;
import assets.StandaloneAssetPath;
import gfx.basic_components.ARPImage;
import gfx.basic_components.AutosizingLabel;
import gfx.basic_components.utils.DimValue;
import haxe.ui.containers.HBox;

class StudyFilterRect extends HBox
{
    public var tagLabel:AutosizingLabel;
    public var cross:ARPImage;

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        var spacing:Float = 0.16 * height;
        customStyle = {
            horizontalSpacing: spacing,
            paddingTop: spacing,
            paddingBottom: spacing,
            paddingLeft: spacing,
            paddingRight: spacing,
            backgroundColor: 0x7fc7ff
        };
    }

    public function new(h:DimValue, tagName:String, onRemovePressed:Void->Void, removeBtnTooltip:Phrase)
    {
        if (h == Auto)
            throw "autoHeight cannot be true for StudyFilterRect";

        super();

        assignHeight(this, h);

        tagLabel = new AutosizingLabel();
        tagLabel.align = Left;
        tagLabel.sizePerCharHeight = 0.9;
        tagLabel.percentHeight = 100;
        tagLabel.text = tagName;
        tagLabel.customStyle.color = 0x0a4761;
        addComponent(tagLabel);

        cross = new ARPImage();
        cross.resource = StudyTagFilterCross;
        cross.tooltip = Dictionary.getPhrase(removeBtnTooltip);
        cross.percentHeight = 100;
        cross.customStyle.horizontalAlign = "center";
        cross.customStyle.backgroundColor = 0;
        cross.customStyle.backgroundOpacity = 0;
        cross.customStyle.pointerEvents = 'true';
        cross.onClick = e -> {onRemovePressed();};
        addComponent(cross);
    }
}
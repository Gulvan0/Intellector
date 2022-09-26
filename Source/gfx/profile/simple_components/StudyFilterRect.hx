package gfx.profile.simple_components;

import dict.Dictionary;
import utils.AssetManager;
import gfx.basic_components.ARPImage;
import gfx.basic_components.AutosizingLabel;
import gfx.basic_components.utils.DimValue;
import haxe.ui.containers.HBox;

class StudyFilterRect extends HBox
{
    public var tagLabel:AutosizingLabel;
    public var cross:ARPImage;

    public function new(h:DimValue, tagName:String, onRemovePressed:Void->Void)
    {
        if (h == Auto)
            throw "autoHeight cannot be true for StudyFilterRect";

        super();

        assignHeight(this, h);

        var spacing:Float = 0.16 * height;
        customStyle.horizontalSpacing = spacing;
        customStyle.paddingTop = spacing;
        customStyle.paddingBottom = spacing;
        customStyle.paddingLeft = spacing;
        customStyle.paddingRight = spacing;
        customStyle.backgroundColor = 0x7fc7ff;

        tagLabel = new AutosizingLabel();
        tagLabel.percentHeight = 100;
        tagLabel.text = tagName;
        tagLabel.customStyle.color = 0x0a4761;
        addComponent(tagLabel);

        cross = new ARPImage();
        cross.resource = AssetManager.singleAssetPath(StudyTagFilterCross);
        cross.tooltip = Dictionary.getPhrase(PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP);
        cross.percentHeight = 100;
        cross.customStyle.horizontalAlign = "center";
        cross.customStyle.backgroundColor = 0;
        cross.customStyle.backgroundOpacity = 0;
        cross.customStyle.pointerEvents = 'true';
        cross.onClick = e -> {onRemovePressed();};
        addComponent(cross);
    }
}
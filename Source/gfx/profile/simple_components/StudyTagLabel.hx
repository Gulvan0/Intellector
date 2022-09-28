package gfx.profile.simple_components;

import utils.AssetManager;
import gfx.basic_components.utils.DimValue;
import gfx.basic_components.AnnotatedImage;

class StudyTagLabel extends AnnotatedImage
{
    public function new(heightDim:DimValue, tag:String, onClick:Void->Void)
    {
        super(Auto, heightDim, AssetManager.singleAssetPath(StudyTagLabel), tag);

        lbl.styleNames = "link";
        lbl.onClick = e -> {onClick();};
    }
}
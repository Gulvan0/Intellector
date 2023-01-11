package gfx.profile.simple_components;

import assets.StandaloneAssetPath;
import gfx.basic_components.utils.DimValue;
import gfx.basic_components.AnnotatedImage;

class StudyTagLabel extends AnnotatedImage
{
    public function new(heightDim:DimValue, tag:String, onClick:Void->Void)
    {
        super(Auto, heightDim, StudyTagLabel, tag);

        lbl.styleNames = "link";
        lbl.onClick = e -> {onClick();};
    }
}
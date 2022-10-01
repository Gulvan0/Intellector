package gfx.profile.complex_components;

import haxe.ui.styles.Style;
import gfx.basic_components.utils.DimValue;
import gfx.profile.simple_components.StudyTagLabel;
import gfx.basic_components.AutosizingLabel;
import dict.Dictionary;
import haxe.ui.containers.ScrollView;

class StudyTagList extends ScrollView
{
    public function new(w:DimValue, contentHeight:Float, tags:Array<String>, onTagClicked:String->Void)
    {
        super();

        this.contentLayoutName = 'horizontal';
        this.contentHeight = contentHeight;

        assignWidth(this, w);

        var titleLabel:AutosizingLabel = new AutosizingLabel();
        titleLabel.text = Dictionary.getPhrase(PROFILE_STUDY_TAG_LABELS_PREPENDER);
        titleLabel.percentHeight = 100;
        addComponent(titleLabel);
        
        if (Lambda.empty(tags))
        {
            var noneLabel:AutosizingLabel = new AutosizingLabel();
            noneLabel.text = Dictionary.getPhrase(PROFILE_STUDY_NO_TAGS_PLACEHOLDER);
            noneLabel.customStyle = {color: 0x999999, fontItalic: true};
            noneLabel.percentHeight = 100;
            addComponent(noneLabel);
        }

        for (tag in tags)
            addComponent(new StudyTagLabel(Percent(100), tag, onTagClicked.bind(tag)));
    }
}
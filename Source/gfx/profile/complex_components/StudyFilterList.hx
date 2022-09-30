package gfx.profile.complex_components;

import dict.Phrase;
import gfx.basic_components.utils.DimValue;
import dict.Dictionary;
import haxe.ui.containers.HBox;
import gfx.profile.simple_components.StudyFilterRect;
import gfx.basic_components.AutosizingLabel;
import haxe.ui.containers.ScrollView;

using utils.StringUtils;
using StringTools;

class StudyFilterList extends ScrollView
{
    private var onTagAdded:String->Void;
    private var onTagRemoved:String->Void;
    private var onTagsCleared:Void->Void;

    private var tagRects:Map<String, StudyFilterRect> = [];

    private var noneLabel:AutosizingLabel;
    private var tagBox:HBox;

    private var removeTagTooltip:Phrase;
    private var promptQuestion:Phrase;

    public function appendTag(name:String)
    {
        addTag(name, true);
    }

    private function addTag(name:String, ignoreCallback:Bool)
    {
        name = name.shorten(StudyTag, false);
        name = name.trim();

        if (tagRects.exists(name))
            return;

        noneLabel.hidden = true;

        var rect:StudyFilterRect = new StudyFilterRect(Percent(100), name, removeTag.bind(name), removeTagTooltip);
        tagBox.addComponent(rect);
        tagRects.set(name, rect);
        if (!ignoreCallback)
            onTagAdded(name);
    }

    private function removeTag(name:String)
    {
        tagBox.removeComponent(tagRects.get(name));
        tagRects.remove(name);

        if (Lambda.empty(tagRects))
            noneLabel.hidden = false;

        onTagRemoved(name);
    }

    private function onAddNewTagPressed(e)
    {
        Dialogs.prompt(promptQuestion, None, addTag.bind(_, false));
    }

    private function onClearTagsPressed(e)
    {
        noneLabel.hidden = false;
        tagRects = [];
        tagBox.removeAllComponents();
        onTagsCleared();
    }

    public function new(w:DimValue, contentHeight:Float, onTagAdded:String->Void, onTagRemoved:String->Void, onTagsCleared:Void->Void, prepender:Phrase, noTagsPlaceholder:Phrase, addTag:Phrase, removeTag:Phrase, clear:Phrase, promptQuestion:Phrase)
    {
        super();
        this.promptQuestion = promptQuestion;
        this.removeTagTooltip = removeTag;

        this.onTagAdded = onTagAdded;
        this.onTagRemoved = onTagRemoved;
        this.onTagsCleared = onTagsCleared;

        this.contentLayoutName = 'horizontal';
        this.contentHeight = contentHeight;
        assignWidth(this, w);
        
        var titleLabel:AutosizingLabel = new AutosizingLabel();
        titleLabel.text = Dictionary.getPhrase(prepender);
        titleLabel.percentHeight = 100;
        addComponent(titleLabel);
        
        noneLabel = new AutosizingLabel();
        noneLabel.text = Dictionary.getPhrase(noTagsPlaceholder);
        noneLabel.customStyle = {color: 0x999999, fontItalic: true};
        noneLabel.percentHeight = 100;
        addComponent(noneLabel);

        tagBox = new HBox();
        tagBox.percentHeight = 100;
        addComponent(tagBox);

        var addNewTagLink:AutosizingLabel = new AutosizingLabel();
        addNewTagLink.percentHeight = 100;
        addNewTagLink.text = Dictionary.getPhrase(addTag);
        addNewTagLink.styleNames = "link";
        addNewTagLink.onClick = onAddNewTagPressed;
        addComponent(addNewTagLink);

        var clearTagsLink:AutosizingLabel = new AutosizingLabel();
        clearTagsLink.percentHeight = 100;
        clearTagsLink.text = Dictionary.getPhrase(clear);
        clearTagsLink.styleNames = "link";
        clearTagsLink.onClick = onClearTagsPressed;
        addComponent(clearTagsLink);
    }
}
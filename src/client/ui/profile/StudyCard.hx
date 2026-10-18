package client.ui.profile;

import client.datatypes.study.StudySummary;
import client.ui.common.DragScrollRow;
import client.ui.common.board.BoardPreview;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;

using StringTools;
using client.ui.ComponentExtension;

/**
    A study as a card: its key position, name, description and tags. The card opens the study; a tag
    adds itself to the tag filter, and one already in it is shown selected.
**/
class StudyCard extends HBox
{
    private static inline final BOARD_WIDTH:Float = 132;

    /** `filterTags`: the tags of the filter, compared case-insensitively **/
    public function new(study:StudySummary, filterTags:Array<String>, onOpen:StudySummary->Void, onTagPicked:String->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_RECORD_CARD);
        this.trackHover();
        registerEvent(MouseEvent.CLICK, _ -> onOpen(study));

        addComponent(new BoardPreview(study.keyPosition, White, BOARD_WIDTH));

        var column:VBox = new VBox();
        column.percentWidth = 100;
        column.percentHeight = 100;
        column.addClass(StyleClass.GAME_RECORD_CARD_COLUMN);
        addComponent(column);

        var nameLabel:Label = new Label();
        nameLabel.text = study.name;
        nameLabel.percentWidth = 100;
        nameLabel.addClass(StyleClass.STUDY_CARD_NAME);
        column.addComponent(nameLabel);

        var descriptionLabel:Label = new Label();
        descriptionLabel.text = study.description;
        descriptionLabel.percentWidth = 100;
        descriptionLabel.addClass(StyleClass.STUDY_CARD_DESCRIPTION);
        column.addComponent(descriptionLabel);

        var spacer:Box = new Box();
        spacer.percentHeight = 100;
        column.addComponent(spacer);

        var tagRow:DragScrollRow = new DragScrollRow();
        tagRow.percentWidth = 100;
        column.addComponent(tagRow);

        var normalizedFilter:Array<String> = [for (tag in filterTags) normalize(tag)];
        for (tag in study.tags)
        {
            var inFilter:Bool = normalizedFilter.contains(normalize(tag));
            var tagButton:Button = new Button();
            tagButton.text = tag;
            tagButton.tooltip = LocaleUtils.localeBinding("intellector.profile.studies.tag_hint");
            tagButton.addClass(StyleClass.STUDY_TAG);
            tagButton.setClass(StyleClass.STUDY_TAG_SELECTED, inFilter);
            tagButton.onClick = _ -> onTagPicked(tag);
            tagRow.addItem(tagButton);
        }
    }

    public static function normalize(tag:String):String
    {
        return tag.trim().toLowerCase();
    }
}

package client.ui.analysis.study;

import client.datatypes.study.StudyPublicity;
import client.formatters.StudyFormatters;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;

/** A study's visibility as a small pill: its icon and name, the full description as the tooltip **/
class StudyPublicityBadge extends HBox
{
    private final image:Image;
    private final label:Label;

    public function new()
    {
        super();
        addClass(StyleClass.STUDY_PUBLICITY_BADGE);
        verticalAlign = "center";

        image = new Image();
        image.verticalAlign = "center";
        addComponent(image);

        label = new Label();
        label.verticalAlign = "center";
        addComponent(label);
    }

    public function setPublicity(publicity:StudyPublicity):Void
    {
        image.resource = Assets.studyPublicityIcon(publicity, false);
        label.text = StudyFormatters.publicityName(publicity);
        tooltip = StudyFormatters.publicityDescription(publicity);
    }
}

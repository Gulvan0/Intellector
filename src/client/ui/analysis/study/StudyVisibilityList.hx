package client.ui.analysis.study;

import client.datatypes.study.StudyPublicity;
import client.formatters.StudyFormatters;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.form.plumbing.FieldHeader;

using client.ui.ComponentExtension;

/** The four visibilities as self-describing rows - icon, name and where it's listed - one of them always chosen **/
class StudyVisibilityList extends VBox
{
    private static final PUBLICITIES:Array<StudyPublicity> = [PUBLIC, PROFILE_AND_LINK_ONLY, LINK_ONLY, PRIVATE];

    public var selected(default, null):StudyPublicity;

    private final rows:Map<StudyPublicity, {row:HBox, icon:Image}> = [];

    public function new(label:String, selected:StudyPublicity, onSelect:StudyPublicity->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.STUDY_VISIBILITY);

        var header:FieldHeader = new FieldHeader(label);
        addComponent(header);

        var list:VBox = new VBox();
        list.percentWidth = 100;
        list.addClass(StyleClass.STUDY_VISIBILITY_LIST);
        addComponent(list);

        for (publicity in PUBLICITIES)
        {
            var row:HBox = new HBox();
            row.percentWidth = 100;
            row.addClass(StyleClass.STUDY_VISIBILITY_OPTION);
            row.tooltip = StudyFormatters.publicityDescription(publicity);
            row.onClick = _ -> {
                select(publicity);
                onSelect(publicity);
            };
            row.trackHover();
            list.addComponent(row);

            var icon:Image = new Image();
            icon.verticalAlign = "center";
            row.addComponent(icon);

            var name:Label = new Label();
            name.text = StudyFormatters.publicityName(publicity);
            name.verticalAlign = "center";
            name.addClass(StyleClass.STUDY_VISIBILITY_NAME);
            row.addComponent(name);

            var spacer:Box = new Box();
            spacer.percentWidth = 100;
            row.addComponent(spacer);

            var scope:Label = new Label();
            scope.text = StudyFormatters.publicityScope(publicity);
            scope.verticalAlign = "center";
            scope.addClass(StyleClass.STUDY_VISIBILITY_SCOPE);
            row.addComponent(scope);

            rows.set(publicity, {row: row, icon: icon});
        }
        select(selected);
    }

    public function select(publicity:StudyPublicity):Void
    {
        selected = publicity;
        for (candidate => parts in rows)
        {
            var on:Bool = candidate == publicity;
            parts.row.setClass(StyleClass.STUDY_VISIBILITY_OPTION_ON, on);
            parts.icon.resource = Assets.studyPublicityIcon(candidate, on);
        }
    }
}

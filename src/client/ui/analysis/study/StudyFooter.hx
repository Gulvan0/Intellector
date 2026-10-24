package client.ui.analysis.study;

import client.formatters.StudyFormatters;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

typedef StudyActions =
{
    onSave:Void->Void,
    onSaveAsNew:Void->Void,
    onEditDetails:Void->Void
}

/**
    How the edits stand, then what can be done with them: the owner saves them, saves them as a new
    study or edits the details; a visitor can only save them as a new study.
**/
class StudyFooter extends VBox
{
    private final hintLabel:Label;
    private final saveButton:Button;
    private final ownerRow:HBox;
    private final saveAsNewButton:Button;
    private final editDetailsButton:Button;
    private final visitorSaveAsNewButton:Button;

    public function new(actions:StudyActions)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.STUDY_FOOTER);

        hintLabel = new Label();
        hintLabel.percentWidth = 100;
        hintLabel.addClass(StyleClass.GAME_HINT);
        hintLabel.addClass(StyleClass.STUDY_SAVE_HINT);
        addComponent(hintLabel);

        saveButton = button("intellector.analysis.study.save_changes", actions.onSave);
        saveButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        addComponent(saveButton);

        ownerRow = new HBox();
        ownerRow.percentWidth = 100;
        ownerRow.addClass(StyleClass.GAME_ACTIONS_ROW);
        saveAsNewButton = button("intellector.analysis.study.save_as_new", actions.onSaveAsNew);
        saveAsNewButton.percentWidth = 50;
        ownerRow.addComponent(saveAsNewButton);
        editDetailsButton = button("intellector.analysis.study.edit_details", actions.onEditDetails);
        editDetailsButton.percentWidth = 50;
        ownerRow.addComponent(editDetailsButton);
        addComponent(ownerRow);

        visitorSaveAsNewButton = button("intellector.analysis.study.save_as_new_study", actions.onSaveAsNew);
        addComponent(visitorSaveAsNewButton);
    }

    /** `locked`: the position editor is open **/
    public function refresh(own:Bool, state:StudySaveState, locked:Bool):Void
    {
        hintLabel.text = StudyFormatters.saveHint(own, state);
        hintLabel.setClass(StyleClass.STUDY_SAVE_HINT_ERROR, own && state == Failed);

        saveButton.hidden = !own;
        ownerRow.hidden = !own;
        visitorSaveAsNewButton.hidden = own;

        saveButton.disabled = locked || !(state == Unsaved || state == Failed);
        saveAsNewButton.disabled = locked || state == Saving;
        editDetailsButton.disabled = locked || state == Saving;
        visitorSaveAsNewButton.disabled = locked;
    }

    private function button(captionKey:String, onPress:Void->Void):Button
    {
        var button:Button = new Button();
        button.text = LocaleUtils.localeBinding(captionKey);
        button.percentWidth = 100;
        button.addClass(StyleClass.GAME_BUTTON);
        button.onClick = _ -> onPress();
        return button;
    }
}

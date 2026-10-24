package client.ui.analysis.study;

import client.datatypes.study.StudyDetails;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.form.TextAreaField;
import haxefolio.form.TextInputField;

using StringTools;

/**
    A study's details as a form: name, description, visibility and tags. The name is required;
    its absence is flagged once the field has been left, or a submit was attempted.
**/
class StudyForm extends VBox
{
    private final nameField:TextInputField;
    private final descriptionField:TextAreaField;
    private final visibilityList:StudyVisibilityList;
    private final tagsField:StudyTagsField;
    private final onEdited:Void->Void;

    private var nameTouched:Bool = false;

    /** `onEdited` follows every edit, when `details` may have changed **/
    public function new(initial:StudyDetails, onEdited:Void->Void)
    {
        super();
        this.onEdited = onEdited;
        percentWidth = 100;
        addClass(StyleClass.STUDY_FORM);

        nameField = new TextInputField(LocaleUtils.localeBinding("intellector.overlay.study.name"), _ -> edited(), null, Plain, StudyDetails.MAX_NAME_LENGTH);
        nameField.placeholder = LocaleUtils.localeBinding("intellector.overlay.study.name_placeholder");
        nameField.currentText = initial.name;
        nameField.element.addEventListener("focusout", () -> {
            nameTouched = true;
            refresh();
        });
        addComponent(nameField);

        descriptionField = new TextAreaField(
            LocaleUtils.localeBinding("intellector.overlay.study.description"),
            _ -> edited(),
            StyleVars.STUDY_DESCRIPTION_HEIGHT,
            StudyDetails.MAX_DESCRIPTION_LENGTH,
            LocaleUtils.localeBinding("intellector.overlay.study.description_placeholder")
        );
        descriptionField.currentText = initial.description;
        addComponent(descriptionField);

        visibilityList = new StudyVisibilityList(LocaleUtils.localeBinding("intellector.overlay.study.visibility"), initial.publicity, _ -> edited());
        addComponent(visibilityList);

        tagsField = new StudyTagsField(initial.tags, edited);
        addComponent(tagsField);

        refresh();
    }

    /** What the form holds, or null while it lacks a name **/
    public function details():Null<StudyDetails>
    {
        var name:String = nameField.currentText.trim();
        if (name.length == 0)
            return null;
        return new StudyDetails(name, descriptionField.currentText, visibilityList.selected, tagsField.tags.copy());
    }

    /** After a submit attempt: flags what's missing **/
    public function revealErrors():Void
    {
        nameTouched = true;
        refresh();
    }

    public function focus():Void
    {
        nameField.focus();
    }

    public function dispose():Void
    {
        nameField.dispose();
        tagsField.dispose();
    }

    private function edited():Void
    {
        refresh();
        onEdited();
    }

    private function refresh():Void
    {
        var nameMissing:Bool = nameTouched && nameField.currentText.trim().length == 0;
        nameField.invalid = nameMissing;
        nameField.hintState = nameMissing ? Error : Normal;
        nameField.hint = nameMissing
            ? LocaleUtils.localeBinding("intellector.overlay.study.name_missing")
            : LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.overlay.study.name_count"), nameField.currentText.length);
        descriptionField.hint = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.overlay.study.description_count"), descriptionField.currentText.length);
    }
}

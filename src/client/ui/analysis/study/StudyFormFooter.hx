package client.ui.analysis.study;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.structure.ActionButton;

typedef StudyFormFooterActions =
{
    onCancel:Void->Void,
    onSubmit:Void->Void,
    /** Null: no Delete study **/
    ?onDelete:Void->Void
}

/**
    The form overlay's footer: Delete study (when deletable) and the failure of the last request on
    the left, Cancel and the primary action on the right. Delete study asks first, the question
    taking the footer over until it's answered. Collapsed, the left part sits above the buttons.
**/
class StudyFormFooter extends VBox
{
    private final messageLabel:Label;
    private final deleteButton:Null<ActionButton>;
    private final cancelButton:ActionButton;
    private final submitButton:ActionButton;
    private final keepButton:ActionButton;
    private final confirmDeleteButton:ActionButton;
    private final actions:StudyFormFooterActions;

    private var asking:Bool = false;
    private var busy:Bool = false;
    private var submittable:Bool = true;

    public function new(submitCaptionKey:String, actions:StudyFormFooterActions, collapsed:Bool)
    {
        super();
        this.actions = actions;
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.STUDY_FORM_FOOTER);

        var leading:HBox = new HBox();
        leading.addClass(StyleClass.STUDY_FORM_FOOTER_ROW);
        var trailing:HBox = new HBox();
        trailing.addClass(StyleClass.STUDY_FORM_FOOTER_ROW);

        if (actions.onDelete != null)
        {
            deleteButton = new ActionButton(LocaleUtils.localeBinding("intellector.overlay.study.delete"), ask, false, Assets.analysisIcon("delete"));
            deleteButton.addClass(StyleClass.STUDY_FORM_DELETE);
            deleteButton.verticalAlign = "center";
            leading.addComponent(deleteButton);
        }
        else
            deleteButton = null;

        messageLabel = new Label();
        messageLabel.percentWidth = 100;
        messageLabel.verticalAlign = "center";
        messageLabel.addClass(StyleClass.STUDY_FORM_MESSAGE);
        leading.addComponent(messageLabel);

        cancelButton = new ActionButton(LocaleUtils.localeBinding("intellector.overlay.study.cancel"), actions.onCancel);
        submitButton = new ActionButton(LocaleUtils.localeBinding(submitCaptionKey), actions.onSubmit, true);
        keepButton = new ActionButton(LocaleUtils.localeBinding("intellector.overlay.study.keep"), stopAsking);
        confirmDeleteButton = new ActionButton(LocaleUtils.localeBinding("intellector.overlay.study.delete_confirm"), confirmDelete, true);
        for (button in [cancelButton, submitButton, keepButton, confirmDeleteButton])
        {
            button.verticalAlign = "center";
            trailing.addComponent(button);
        }

        if (collapsed)
        {
            addClass(StyleClass.STUDY_FORM_FOOTER_COLLAPSED);
            leading.percentWidth = 100;
            trailing.percentWidth = 100;
            for (button in [cancelButton, submitButton, keepButton, confirmDeleteButton])
                button.percentWidth = 50;
            if (deleteButton != null)
                deleteButton.percentWidth = 100;
            addComponent(leading);
            addComponent(trailing);
        }
        else
        {
            var row:HBox = new HBox();
            row.percentWidth = 100;
            row.percentHeight = 100;
            row.addClass(StyleClass.STUDY_FORM_FOOTER_ROW);
            leading.percentWidth = 100;
            leading.verticalAlign = "center";
            trailing.verticalAlign = "center";
            for (button in [cancelButton, submitButton, keepButton, confirmDeleteButton])
                button.width = StyleVars.STUDY_FORM_BUTTON_WIDTH;
            row.addComponent(leading);
            row.addComponent(trailing);
            addComponent(row);
        }
        refresh();
    }

    /** `submittable`: the form holds what the primary action needs **/
    public function setSubmittable(submittable:Bool):Void
    {
        this.submittable = submittable;
        refresh();
    }

    /** While a request is in flight, nothing more can be sent **/
    public function setBusy(busy:Bool):Void
    {
        this.busy = busy;
        refresh();
    }

    /** `messageKey`: the failure to show, null for none **/
    public function setFailure(messageKey:Null<String>):Void
    {
        messageLabel.text = messageKey != null ? LocaleUtils.localeBinding(messageKey) : "";
        messageLabel.removeClass(StyleClass.STUDY_FORM_QUESTION);
    }

    private function ask():Void
    {
        asking = true;
        messageLabel.text = LocaleUtils.localeBinding("intellector.overlay.study.delete_question");
        messageLabel.addClass(StyleClass.STUDY_FORM_QUESTION);
        refresh();
    }

    private function stopAsking():Void
    {
        asking = false;
        setFailure(null);
        refresh();
    }

    private function confirmDelete():Void
    {
        if (!busy && actions.onDelete != null)
            actions.onDelete();
    }

    private function refresh():Void
    {
        if (deleteButton != null)
        {
            deleteButton.hidden = asking;
            deleteButton.enabled = !busy;
        }
        cancelButton.hidden = asking;
        submitButton.hidden = asking;
        keepButton.hidden = !asking;
        confirmDeleteButton.hidden = !asking;
        submitButton.enabled = submittable && !busy;
        confirmDeleteButton.enabled = !busy;
    }
}

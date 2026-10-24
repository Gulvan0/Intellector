package client.ui.analysis.study;

import client.datatypes.study.Study;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    Compact: the open study's name above the board, opening the study sheet, with Save beside it
    for the owner. While the study loads, or once it can't be shown, the bar holds the status.
**/
class StudyBar extends HBox
{
    private final openButton:HBox;
    private final nameLabel:Label;
    private final chevron:Image;
    private final saveButton:Button;
    private final retryButton:Button;

    private var open:Bool = false;
    private var own:Bool = false;
    private var onRetry:Void->Void = () -> {};

    public function new(onOpen:Void->Void, onSave:Void->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.STUDY_BAR);

        openButton = new HBox();
        openButton.percentWidth = 100;
        openButton.addClass(StyleClass.STUDY_BAR_OPEN);
        openButton.tooltip = LocaleUtils.localeBinding("intellector.analysis.study.open_details");
        openButton.onClick = _ -> {
            if (open)
                onOpen();
        };
        openButton.trackHover();
        addComponent(openButton);

        nameLabel = new Label();
        nameLabel.percentWidth = 100;
        nameLabel.verticalAlign = "center";
        nameLabel.addClass(StyleClass.STUDY_BAR_NAME);
        openButton.addComponent(nameLabel);

        chevron = new Image();
        chevron.resource = Assets.analysisIcon("chevron_right");
        chevron.verticalAlign = "center";
        openButton.addComponent(chevron);

        saveButton = new Button();
        saveButton.text = LocaleUtils.localeBinding("intellector.analysis.study.save");
        saveButton.addClass(StyleClass.GAME_BUTTON);
        saveButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        saveButton.addClass(StyleClass.STUDY_BAR_BUTTON);
        saveButton.onClick = _ -> onSave();
        addComponent(saveButton);

        retryButton = new Button();
        retryButton.text = LocaleUtils.localeBinding("intellector.common.load.retry");
        retryButton.addClass(StyleClass.GAME_BUTTON);
        retryButton.addClass(StyleClass.STUDY_BAR_BUTTON);
        retryButton.onClick = _ -> onRetry();
        addComponent(retryButton);

        showLoading();
    }

    public function showLoading():Void
    {
        showStatus("intellector.common.load.loading", false);
    }

    /** `timedOut`: the server didn't answer in time **/
    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        this.onRetry = onRetry;
        showStatus(timedOut ? "intellector.common.load.timeout" : "intellector.common.load.failed", true);
    }

    /** `messageKey`: why it can't be shown **/
    public function showUnavailable(messageKey:String):Void
    {
        showStatus(messageKey, false);
    }

    public function showStudy(study:Study, own:Bool):Void
    {
        open = true;
        this.own = own;
        nameLabel.text = study.details.name;
        refreshParts(false);
    }

    /** `locked`: the position editor is open **/
    public function refresh(state:StudySaveState, locked:Bool):Void
    {
        saveButton.disabled = locked || !(state == Unsaved || state == Failed);
    }

    private function showStatus(messageKey:String, retryable:Bool):Void
    {
        open = false;
        nameLabel.text = LocaleUtils.localeBinding(messageKey);
        refreshParts(retryable);
    }

    private function refreshParts(retryable:Bool):Void
    {
        openButton.setClass(StyleClass.STUDY_BAR_STATUS, !open);
        chevron.hidden = !open;
        saveButton.hidden = !open || !own;
        retryButton.hidden = !retryable;
    }
}

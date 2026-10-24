package client.ui.analysis.study;

import client.datatypes.study.Study;
import client.formatters.StudyFormatters;
import client.ui.analysis.study.StudyFooter.StudyActions;
import client.ui.analysis.variations.NativeScroller;
import client.ui.common.DragScrollRow;
import client.ui.common.LoadStatus;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;

/**
    The open study, above the variations while wide and as a tab of the shared card while medium:
    its number and visibility, the scrolling name, author, dates and description, the tags, then
    the save footer. While the study loads, or once it can't be shown, the card holds the status.
**/
class StudyCard extends VBox
{
    private static inline final OWNER_HEIGHT:Float = 392;
    private static inline final VISITOR_HEIGHT:Float = 344;

    private final topRow:HBox;
    private final titleLabel:Label;
    private final numberLabel:Label;
    private final publicityBadge:StudyPublicityBadge;
    private final body:VBox;
    private final info:StudyInfo;
    private final tagRow:DragScrollRow;
    private final footer:StudyFooter;
    private final status:LoadStatus;
    private final messageLabel:Label;

    private var tagButtons:Array<Button> = [];
    private var shownStudy:Null<Study> = null;
    private var own:Bool = false;
    private var tabbed:Bool = false;
    private var locked:Bool = false;
    private var contentShown:Bool = true;
    private var shownPart:Null<Component> = null;

    public function new(actions:StudyActions)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.STUDY_CARD);

        topRow = new HBox();
        topRow.percentWidth = 100;
        topRow.addClass(StyleClass.STUDY_CARD_TOP);
        addComponent(topRow);

        titleLabel = new Label();
        titleLabel.text = LocaleUtils.localeBinding("intellector.analysis.study.label");
        titleLabel.verticalAlign = "center";
        titleLabel.addClass(StyleClass.STUDY_CARD_TITLE);
        topRow.addComponent(titleLabel);

        numberLabel = new Label();
        numberLabel.verticalAlign = "center";
        numberLabel.addClass(StyleClass.STUDY_NUMBER);
        topRow.addComponent(numberLabel);

        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        topRow.addComponent(spacer);

        publicityBadge = new StudyPublicityBadge();
        topRow.addComponent(publicityBadge);

        body = new VBox();
        body.percentWidth = 100;
        body.percentHeight = 100;
        body.addClass(StyleClass.STUDY_CARD_BODY);
        addComponent(body);

        info = new StudyInfo();
        body.addComponent(new NativeScroller(info, false));

        tagRow = new DragScrollRow();
        tagRow.percentWidth = 100;
        tagRow.addClass(StyleClass.STUDY_TAG_ROW);
        body.addComponent(tagRow);

        footer = new StudyFooter(actions);
        body.addComponent(footer);

        status = new LoadStatus();
        status.addClass(StyleClass.STUDY_CARD_STATUS);
        addComponent(status);

        messageLabel = new Label();
        messageLabel.percentWidth = 100;
        messageLabel.addClass(StyleClass.STUDY_CARD_MESSAGE);
        addComponent(messageLabel);

        showLoading();
    }

    public function showLoading():Void
    {
        status.showLoading();
        showOnly(status);
    }

    /** `timedOut`: the server didn't answer in time **/
    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        status.showFailure(timedOut, onRetry);
        showOnly(status);
    }

    /** `messageKey`: why it can't be shown **/
    public function showUnavailable(messageKey:String):Void
    {
        messageLabel.text = LocaleUtils.localeBinding(messageKey);
        showOnly(messageLabel);
    }

    public function showStudy(study:Study, own:Bool):Void
    {
        shownStudy = study;
        this.own = own;
        numberLabel.text = StudyFormatters.number(study);
        publicityBadge.setPublicity(study.details.publicity);
        info.setStudy(study, own);

        tagRow.clearItems();
        tagButtons = StudyTagButtons.create(study);
        for (button in tagButtons)
        {
            button.disabled = locked;
            tagRow.addItem(button);
        }
        tagRow.hidden = tagButtons.length == 0;
        showOnly(body);
    }

    public function refreshFooter(state:StudySaveState):Void
    {
        footer.refresh(own, state, locked);
    }

    /** Disabled in place while the position editor is open **/
    public function setLocked(locked:Bool, state:StudySaveState):Void
    {
        this.locked = locked;
        for (button in tagButtons)
            button.disabled = locked;
        footer.refresh(own, state, locked);
    }

    /** Hidden, the card is reduced to whatever is added above its content, such as tabs **/
    public function setContentShown(shown:Bool):Void
    {
        contentShown = shown;
        refreshParts();
    }

    /** Tabbed (medium), the tab names the card and the card fills its slot; otherwise its height is fixed **/
    public function setTabbed(tabbed:Bool):Void
    {
        this.tabbed = tabbed;
        titleLabel.hidden = tabbed;
        refreshHeight();
    }

    private function showOnly(part:Component):Void
    {
        shownPart = part;
        if (part != body)
            shownStudy = null;
        refreshParts();
    }

    private function refreshParts():Void
    {
        var open:Bool = shownPart == body;
        topRow.hidden = !contentShown;
        body.hidden = !contentShown || !open;
        status.hidden = !contentShown || shownPart != status;
        messageLabel.hidden = !contentShown || shownPart != messageLabel;
        numberLabel.hidden = !open;
        publicityBadge.hidden = !open || !own;
        refreshHeight();
    }

    private function refreshHeight():Void
    {
        if (tabbed || !contentShown)
        {
            height = null;
            percentHeight = contentShown ? 100 : null;
        }
        else if (shownPart == messageLabel)
        {
            percentHeight = null;
            height = null;
        }
        else
        {
            percentHeight = null;
            height = shownStudy != null && !own ? VISITOR_HEIGHT : OWNER_HEIGHT;
        }
        invalidateComponentLayout(); // a null size alone doesn't return it to its auto height
    }
}

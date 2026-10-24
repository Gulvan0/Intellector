package client.ui.home;

import client.datatypes.challenge.OpenChallenge;
import client.formatters.GameFormatters;
import client.ui.common.challenges.TimeControlTag;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

typedef OpenChallengeRowHandlers =
{
    /** Accept, or Cancel on the viewer's own challenge **/
    onAction:OpenChallenge->Void,
    onCustomPressed:OpenChallengeRow->Void,
    onCustomHovered:OpenChallengeRow->Bool->Void
}

/**
    An open challenge, its facts in the order: caller (with the rating of a rated challenge), time
    control, rated or casual, the colour the accepter plays, the starting position, then Accept.
    Wide: one line under the panel's column headers. Narrow: two lines, the colour's label shortened.
**/
class OpenChallengeRow extends HBox
{
    public static inline final WIDE_HEIGHT:Float = 48;
    public static inline final NARROW_HEIGHT:Float = 64;

    public final challenge:OpenChallenge;

    private final actionButton:Button;
    private var customChip:Null<HBox> = null;
    private var customIcon:Null<Image> = null;
    private var customLabel:Null<Label> = null;

    /** `own`: the viewer's challenge, which they can only cancel **/
    public function new(challenge:OpenChallenge, own:Bool, narrow:Bool, handlers:OpenChallengeRowHandlers)
    {
        super();
        this.challenge = challenge;
        percentWidth = 100;
        addClass(StyleClass.HOME_CHALLENGE_ROW);
        this.setClass(StyleClass.HOME_NARROW, narrow);

        actionButton = new Button();
        actionButton.text = LocaleUtils.localeBinding(own ? "intellector.home.challenges.cancel" : "intellector.home.challenges.accept");
        actionButton.addClass(StyleClass.GAME_BUTTON);
        actionButton.addClass(StyleClass.HOME_CHALLENGE_ACTION);
        actionButton.setClass(StyleClass.HOME_NARROW, narrow);
        actionButton.verticalAlign = "center";
        actionButton.onClick = _ -> handlers.onAction(challenge);

        if (narrow)
            buildNarrow(handlers);
        else
            buildWide(handlers);

        addComponent(actionButton);
    }

    /** The Custom chip, which the position preview is placed against; null for the default position **/
    public function customAnchor():Null<Component>
    {
        return customChip;
    }

    public function setPreviewOpen(open:Bool):Void
    {
        if (customChip == null)
            return;
        customChip.setClass(StyleClass.HOME_CUSTOM_CHIP_OPEN, open);
        customLabel.setClass(StyleClass.HOME_CUSTOM_CHIP_OPEN, open);
        customIcon.resource = Assets.homeIcon(open ? "custom_position_open" : "custom_position");
    }

    public function setBusy(busy:Bool):Void
    {
        actionButton.disabled = busy;
    }

    private function buildWide(handlers:OpenChallengeRowHandlers):Void
    {
        var playerCell:HBox = createCell(null);
        playerCell.percentWidth = 100;
        addPlayer(playerCell);
        addComponent(playerCell);

        var timeControlCell:HBox = createCell(OpenChallengesCard.TIME_CONTROL_COLUMN_WIDTH);
        timeControlCell.addComponent(createTimeControlTag());
        addComponent(timeControlCell);

        var typeCell:HBox = createCell(OpenChallengesCard.TYPE_COLUMN_WIDTH);
        typeCell.addComponent(createRatedLabel());
        addComponent(typeCell);

        var colorCell:HBox = createCell(OpenChallengesCard.COLOR_COLUMN_WIDTH);
        addColor(colorCell, "color");
        addComponent(colorCell);

        var startCell:HBox = createCell(OpenChallengesCard.START_COLUMN_WIDTH);
        addPosition(startCell, handlers, true);
        addComponent(startCell);
    }

    private function buildNarrow(handlers:OpenChallengeRowHandlers):Void
    {
        var column:VBox = new VBox();
        column.percentWidth = 100;
        column.addClass(StyleClass.HOME_CHALLENGE_LINES);
        column.verticalAlign = "center";
        addComponent(column);

        var topLine:HBox = createCell(null);
        topLine.percentWidth = 100;
        addPlayer(topLine);
        topLine.addComponent(createSpacer());
        addColor(topLine, "color_short");
        column.addComponent(topLine);

        var bottomLine:HBox = createCell(null);
        bottomLine.percentWidth = 100;
        bottomLine.addComponent(createTimeControlTag());
        bottomLine.addComponent(createRatedLabel());
        bottomLine.addComponent(createSpacer());
        addPosition(bottomLine, handlers, false);
        column.addComponent(bottomLine);
    }

    private function createCell(width:Null<Float>):HBox
    {
        var cell:HBox = new HBox();
        if (width != null)
            cell.width = width;
        cell.addClass(StyleClass.HOME_CHALLENGE_CELL);
        cell.verticalAlign = "center";
        return cell;
    }

    private function createSpacer():Box
    {
        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        return spacer;
    }

    private function addPlayer(cell:HBox):Void
    {
        var nicknameLabel:Label = new Label();
        nicknameLabel.text = challenge.callerNickname;
        nicknameLabel.addClass(StyleClass.HOME_CHALLENGE_NICKNAME);
        nicknameLabel.verticalAlign = "center";
        cell.addComponent(nicknameLabel);

        if (challenge.rated && challenge.callerRating != null)
        {
            var ratingLabel:Label = new Label();
            ratingLabel.text = GameFormatters.bareRating(challenge.callerRating);
            ratingLabel.addClass(StyleClass.GAME_RECORD_RATING);
            ratingLabel.verticalAlign = "center";
            cell.addComponent(ratingLabel);
        }
    }

    private function createTimeControlTag():TimeControlTag
    {
        var tag:TimeControlTag = new TimeControlTag();
        tag.addClass(StyleClass.HOME_CHALLENGE_TIME_CONTROL);
        tag.setTimeControl(challenge.timeControl, challenge.timeControlKind);
        return tag;
    }

    private function createRatedLabel():Label
    {
        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding(challenge.rated ? "intellector.common.game_type.rated" : "intellector.common.game_type.casual");
        label.addClass(StyleClass.GAME_RECORD_MUTED);
        label.verticalAlign = "center";
        return label;
    }

    /** `keyGroup`: `color` for the full label, `color_short` for the narrow one **/
    private function addColor(cell:HBox, keyGroup:String):Void
    {
        var colorName:String = challenge.acceptorColor.getName().toLowerCase();

        var swatch:Image = new Image();
        swatch.resource = Assets.colorIcon(challenge.acceptorColor.getColor());
        swatch.width = 14;
        swatch.height = 14;
        swatch.scaleMode = "fitinside";
        swatch.verticalAlign = "center";
        cell.addComponent(swatch);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding('intellector.home.challenges.$keyGroup.$colorName');
        label.addClass(StyleClass.GAME_RECORD_TEXT);
        label.verticalAlign = "center";
        cell.addComponent(label);
    }

    /** `hoverOpens`: a mouse layout, where hovering the chip previews the position; otherwise only a tap does **/
    private function addPosition(cell:HBox, handlers:OpenChallengeRowHandlers, hoverOpens:Bool):Void
    {
        if (challenge.customStartingPosition == null)
        {
            var label:Label = new Label();
            label.text = LocaleUtils.localeBinding("intellector.home.challenges.position.default");
            label.addClass(StyleClass.GAME_RECORD_MUTED);
            label.verticalAlign = "center";
            cell.addComponent(label);
            return;
        }

        var chip:HBox = new HBox();
        chip.addClass(StyleClass.HOME_CUSTOM_CHIP);
        chip.setClass(StyleClass.HOME_NARROW, !hoverOpens);
        chip.verticalAlign = "center";
        chip.trackHover();

        var icon:Image = new Image();
        icon.resource = Assets.homeIcon("custom_position");
        icon.width = 14;
        icon.height = 12;
        icon.verticalAlign = "center";
        chip.addComponent(icon);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding("intellector.home.challenges.position.custom");
        label.addClass(StyleClass.HOME_CUSTOM_CHIP_TEXT);
        label.verticalAlign = "center";
        chip.addComponent(label);

        customChip = chip;
        customIcon = icon;
        customLabel = label;

        // a tap needs 44 px: on a phone the chip sits in a taller, invisible target overhanging its line
        var target:Component = chip;
        if (!hoverOpens)
        {
            target = new Box();
            target.addClass(StyleClass.HOME_CUSTOM_TAP_TARGET);
            target.verticalAlign = "center";
            target.addComponent(chip);
        }
        target.registerEvent(MouseEvent.CLICK, _ -> handlers.onCustomPressed(this));
        if (hoverOpens)
        {
            target.registerEvent(MouseEvent.MOUSE_OVER, _ -> handlers.onCustomHovered(this, true));
            target.registerEvent(MouseEvent.MOUSE_OUT, _ -> handlers.onCustomHovered(this, false));
        }
        cell.addComponent(target);
    }
}

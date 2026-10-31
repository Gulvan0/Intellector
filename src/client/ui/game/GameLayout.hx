package client.ui.game;

import client.datatypes.game.GameChatMessage;
import client.ui.common.board.BoardControlRow;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;

using client.ui.ComponentExtension;

enum SheetTab
{
    Chat;
    Moves;
    Info;
}

/**
    Arranges the page's parts. Wide: info and chat | the board | moves and actions. Medium: a header
    line over the board | moves, chat and actions; the info card's facts move to the header and the
    moves card. Compact: a header line, the move strip, the board, the actions, then a chat peek (the
    only way to open the chat) with the Moves / Info tabs under it; an open tab shows its card on a sheet floating just above
    the tabs, over the peek and whatever else it reaches, so the page never grows. Rail: the board
    alone, filling the height | a narrow column of the top player, the move strip, the board's
    control row, the actions as icons, the Chat / Moves / Info tabs and the bottom player, centered
    vertically; an open tab shows its card over the board.
**/
class GameLayout extends Box
{
    private static inline final SIDE_COLUMN_WIDTH:Float = 312;
    // until the page measures the height there is: the wide columns resolve their heights against a fixed one
    private static inline final PROVISIONAL_WIDE_HEIGHT:Float = 520;
    // medium: the moves and the chat share the column's height 3:2
    private static inline final MEDIUM_MOVES_SHARE:Float = 60;
    private static inline final MEDIUM_CHAT_SHARE:Float = 40;
    private static inline final RAIL_COLUMN_WIDTH:Float = 216;
    private static inline final MEDIUM_HEAD_SPACING:Float = 12; // between the head's labels; keep in step with the stylesheet

    private final infoCard:GameInfoCard;
    private final chatCard:ChatCard;
    private final movesCard:MovesCard;
    private final actionsCard:ActionsCard;
    private final stage:BoardStage;
    private final moveStrip:MoveStrip;

    private final leftColumn:VBox;
    private final rightColumn:VBox;
    private final wideRow:HBox;

    private final compactColumn:VBox;
    private final headRow:HBox;
    private final tabRow:HBox;
    private final headTimeControlLabel:Label;
    private final headDetailsLabel:Label;
    private final headSpacer:Box;
    private final headResolutionLabel:Label;
    private final peekButton:HBox;
    private final peekLabel:Label;
    private final unreadBadge:Label;
    private final sheet:Box;
    // compact: the sheet is shorter than the info card, so the card scrolls inside a frame of its own
    private final infoFrame:VBox;
    private final infoScrollArea:ScrollArea;
    private final tabButtons:Map<SheetTab, Button> = [];

    private final railRow:HBox;
    private final boardArea:Box;
    private final railColumn:VBox;
    private final railTabRow:HBox;
    private final railSheet:Box;
    private final railUnreadBadge:Label;
    private final railTabButtons:Map<SheetTab, Button> = [];
    private var controls:Null<BoardControlRow> = null;

    private var tier:Null<BoardLayoutTier> = null;
    private var openTab:Null<SheetTab> = null;
    private var unreadCount:Int = 0;

    public function new(infoCard:GameInfoCard, chatCard:ChatCard, movesCard:MovesCard, actionsCard:ActionsCard, stage:BoardStage, moveStrip:MoveStrip)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_LAYOUT);

        this.infoCard = infoCard;
        this.chatCard = chatCard;
        this.movesCard = movesCard;
        this.actionsCard = actionsCard;
        this.stage = stage;
        this.moveStrip = moveStrip;

        wideRow = new HBox();
        wideRow.percentWidth = 100;
        wideRow.percentHeight = 100;
        wideRow.addClass(StyleClass.GAME_WIDE_ROW);

        leftColumn = createSideColumn();
        rightColumn = createSideColumn();

        compactColumn = new VBox();
        compactColumn.percentWidth = 100;
        compactColumn.addClass(StyleClass.GAME_COMPACT_COLUMN);

        headRow = new HBox();
        headRow.percentWidth = 100;
        headRow.addClass(StyleClass.GAME_HEAD);
        headTimeControlLabel = new Label();
        headTimeControlLabel.addClass(StyleClass.GAME_MONO);
        headTimeControlLabel.verticalAlign = "center";
        headRow.addComponent(headTimeControlLabel);
        headDetailsLabel = new Label();
        headDetailsLabel.percentWidth = 100;
        headDetailsLabel.addClass(StyleClass.GAME_HINT);
        headDetailsLabel.wordWrap = false; // a wrapping head would make the head's height, and so the board's width, depend on each other
        headDetailsLabel.verticalAlign = "center";
        headRow.addComponent(headDetailsLabel);
        headSpacer = new Box();
        headSpacer.percentWidth = 100;
        headRow.addComponent(headSpacer);
        headResolutionLabel = new Label();
        headResolutionLabel.addClass(StyleClass.GAME_RESOLUTION);
        headResolutionLabel.verticalAlign = "center";
        headRow.addComponent(headResolutionLabel);
        compactColumn.addComponent(headRow);

        peekButton = new HBox();
        peekButton.percentWidth = 100;
        peekButton.addClass(StyleClass.GAME_PEEK);
        peekButton.tooltip = LocaleUtils.localeBinding("intellector.live_game.tab.open_chat");
        peekButton.onClick = _ -> setOpenTab(Chat);
        peekButton.trackHover();
        var peekIcon:Image = new Image();
        peekIcon.resource = GameButtons.icon("chat");
        peekIcon.width = 16;
        peekIcon.height = 16;
        peekIcon.verticalAlign = "center";
        peekButton.addComponent(peekIcon);
        peekLabel = new Label();
        peekLabel.percentWidth = 100;
        peekLabel.addClass(StyleClass.GAME_PEEK_TEXT);
        peekLabel.verticalAlign = "center";
        peekButton.addComponent(peekLabel);
        unreadBadge = new Label();
        unreadBadge.addClass(StyleClass.GAME_BADGE);
        unreadBadge.verticalAlign = "center";
        unreadBadge.hidden = true;
        peekButton.addComponent(unreadBadge);

        sheet = new Box();
        sheet.percentWidth = 100;
        sheet.verticalAlign = "bottom";
        sheet.addClass(StyleClass.GAME_SHEET);

        infoScrollArea = new ScrollArea(infoCard);
        infoScrollArea.percentHeight = 100;
        infoFrame = new VBox();
        infoFrame.percentWidth = 100;
        infoFrame.percentHeight = 100;
        infoFrame.addClass(StyleClass.GAME_CARD);
        infoFrame.addComponent(infoScrollArea);

        tabRow = new HBox();
        tabRow.percentWidth = 100;
        tabRow.addClass(StyleClass.GAME_TABS);
        for (tab in [Moves, Info])
        {
            var button:Button = new Button();
            button.percentWidth = 50;
            button.text = LocaleUtils.localeBinding('intellector.live_game.tab.${tab.getName().toLowerCase()}');
            button.addClass(StyleClass.GAME_BUTTON);
            button.addClass(StyleClass.GAME_TAB);
            button.onClick = _ -> setOpenTab(openTab == tab ? null : tab);
            tabButtons.set(tab, button);
            tabRow.addComponent(button);
        }

        railRow = new HBox();
        railRow.percentWidth = 100;
        railRow.percentHeight = 100;
        railRow.addClass(StyleClass.GAME_WIDE_ROW);

        // the open tab's card covers the board, leaving the column and its tabs in reach
        boardArea = new Box();
        boardArea.percentWidth = 100;
        boardArea.percentHeight = 100;
        railRow.addComponent(boardArea);

        railSheet = new Box();
        railSheet.percentWidth = 100;
        railSheet.percentHeight = 100;

        railColumn = createSideColumn();
        railColumn.width = RAIL_COLUMN_WIDTH;
        railColumn.percentHeight = null; // as tall as its parts, centered, rather than leaving a gap above the bottom player
        railColumn.verticalAlign = "center";
        railRow.addComponent(railColumn);

        railUnreadBadge = new Label();
        railUnreadBadge.addClass(StyleClass.GAME_BADGE);
        railUnreadBadge.verticalAlign = "center";
        railUnreadBadge.hidden = true;

        railTabRow = new HBox();
        railTabRow.percentWidth = 100;
        railTabRow.addClass(StyleClass.GAME_TABS);
        for (tab in [Chat, Moves, Info])
        {
            var button:Button = new Button();
            button.percentWidth = 100 / 3;
            button.text = LocaleUtils.localeBinding('intellector.live_game.tab.${tab.getName().toLowerCase()}');
            button.addClass(StyleClass.GAME_BUTTON);
            button.addClass(StyleClass.GAME_TAB);
            button.onClick = _ -> toggleTab(tab);
            railTabButtons.set(tab, button);
            railTabRow.addComponent(button);
            if (tab == Chat)
                railTabRow.addComponent(railUnreadBadge);
        }
    }

    public function setTier(tier:BoardLayoutTier):Void
    {
        if (this.tier == tier)
            return;
        this.tier = tier;

        stage.setHeader(null);
        detachParts();
        removeAllComponents(false);

        var compact:Bool = tier == Compact;
        var rail:Bool = tier == Rail;
        openTab = null;
        infoCard.setClass(StyleClass.GAME_CARD, !hasSheet()); // on a sheet, its frame draws the card
        actionsCard.setCompact(compact || rail);
        movesCard.setNavigationShown(!hasSheet());
        movesCard.setOpeningShown(tier == Medium || rail);
        moveStrip.setTier(tier);
        stage.setFitsHeight(!compact);
        stage.setBarsHosted(!rail);
        for (bar in [stage.topBar, stage.bottomBar])
            bar.setRatingShown(!rail);
        headDetailsLabel.hidden = tier != Medium;
        headSpacer.hidden = tier == Medium;
        fitHeadDetails();

        if (rail)
        {
            if (height == null)
                height = PROVISIONAL_WIDE_HEIGHT;
            infoCard.percentHeight = null;
            chatCard.percentHeight = 100;
            movesCard.percentHeight = 100;
            infoScrollArea.addComponent(infoCard);

            controls = stage.claimControls();
            boardArea.addComponent(stage);
            boardArea.addComponent(railSheet);
            for (part in ([stage.topBar, moveStrip, controls, actionsCard, railTabRow, stage.bottomBar] : Array<Component>))
                railColumn.addComponent(part);
            addComponent(railRow);
            refreshTab();
        }
        else if (compact)
        {
            height = null;
            invalidateComponentLayout();
            infoCard.percentHeight = null;
            chatCard.percentHeight = 100;
            movesCard.percentHeight = 100;

            infoScrollArea.addComponent(infoCard);
            compactColumn.addComponent(headRow);
            compactColumn.addComponent(moveStrip);
            compactColumn.addComponent(stage);
            compactColumn.addComponent(actionsCard);
            compactColumn.addComponent(peekButton);
            compactColumn.addComponent(tabRow);
            addComponent(compactColumn);
            addComponent(sheet);
            refreshTab();
        }
        else if (tier == Medium)
        {
            if (height == null)
                height = PROVISIONAL_WIDE_HEIGHT;
            movesCard.percentHeight = MEDIUM_MOVES_SHARE;
            chatCard.percentHeight = MEDIUM_CHAT_SHARE;

            rightColumn.addComponent(movesCard);
            rightColumn.addComponent(chatCard);
            rightColumn.addComponent(actionsCard);
            wideRow.addComponent(stage);
            wideRow.addComponent(rightColumn);
            addComponent(wideRow);
            stage.setHeader(headRow);
        }
        else
        {
            if (height == null)
                height = PROVISIONAL_WIDE_HEIGHT;
            infoCard.percentHeight = null;
            chatCard.percentHeight = 100;
            movesCard.percentHeight = 100;

            leftColumn.addComponent(infoCard);
            leftColumn.addComponent(chatCard);
            rightColumn.addComponent(movesCard);
            rightColumn.addComponent(actionsCard);
            wideRow.addComponent(leftColumn);
            wideRow.addComponent(stage);
            wideRow.addComponent(rightColumn);
            addComponent(wideRow);
        }
    }

    /** Whether the board, columns and cards fit a height of their own (wide, medium, rail) or flow (compact) **/
    public function isCompact():Bool
    {
        return tier == Compact;
    }

    /** Compact: the most the stage can take of `availableHeight`; the sheet floats, so it takes none. Measured, so call it after a layout **/
    public function compactStageMaxHeight(availableHeight:Float):Float
    {
        var height:Float = 0;
        var partCount:Int = 0;
        for (part in compactColumn.childComponents)
        {
            if (part.hidden)
                continue;
            partCount++;
            if (part != stage)
                height += part.element.offsetHeight;
        }
        var spacing:Float = compactColumn.style.verticalSpacing ?? 0.0;
        return availableHeight - height - spacing * Math.max(0, partCount - 1);
    }

    /** The header's time control text, details (medium only) and resolution line **/
    public function setHeadTexts(timeControlText:Void->String, detailsText:Void->String, resolutionText:Void->String):Void
    {
        LocaleManager.instance.registerComponent(headTimeControlLabel, "text", timeControlText);
        LocaleManager.instance.registerComponent(headDetailsLabel, "text", detailsText);
        LocaleManager.instance.registerComponent(headResolutionLabel, "text", resolutionText);
    }

    /** Medium: shows the head's details only while they fit on one line between the time control and the resolution. Measured, so call it after a layout **/
    public function fitHeadDetails():Void
    {
        if (tier != Medium)
            return;

        var rowWidth:Float = headRow.element.clientWidth;
        if (rowWidth <= 0)
            return;

        var label:js.html.Element = headDetailsLabel.element;
        var meter:js.html.Element = js.Browser.document.createElement("span");
        meter.style.cssText = "position:absolute;visibility:hidden;white-space:nowrap;font:" + js.Browser.window.getComputedStyle(label).font;
        meter.textContent = headDetailsLabel.text;
        js.Browser.document.body.appendChild(meter);
        var detailsWidth:Float = meter.getBoundingClientRect().width;
        meter.remove();

        var availableWidth:Float = rowWidth - headTimeControlLabel.element.getBoundingClientRect().width - headResolutionLabel.element.getBoundingClientRect().width - 2 * MEDIUM_HEAD_SPACING;
        var fits:Bool = detailsWidth <= availableWidth;
        headDetailsLabel.hidden = !fits;
        headSpacer.hidden = fits; // otherwise nothing keeps the resolution at the right
    }

    public function setOpenTab(tab:Null<SheetTab>):Void
    {
        openTab = tab;
        if (tab == Chat)
            setUnreadCount(0);
        refreshTab();
    }

    /** Opens `tab`, or closes it if it's the open one **/
    public function toggleTab(tab:SheetTab):Void
    {
        setOpenTab(openTab == tab ? null : tab);
    }

    /** The latest message, for the peek; `unseen`: it counts as unread unless the chat is in view **/
    public function setLatestMessage(message:Null<GameChatMessage>, unseen:Bool):Void
    {
        peekLabel.text = message != null ? '${LocaleUtils.resolveText(message.authorNickname)}: ${message.text}' : LocaleUtils.localeBinding("intellector.live_game.chat.empty_peek");
        if (unseen && hasSheet() && openTab != Chat)
            setUnreadCount(unreadCount + 1);
    }

    private function setUnreadCount(count:Int):Void
    {
        unreadCount = count;
        for (badge in [unreadBadge, railUnreadBadge])
        {
            badge.hidden = count == 0;
            badge.text = Std.string(count);
        }
    }

    // compact and rail show the open tab's card on a sheet; the other tiers show every card
    private function hasSheet():Bool
    {
        return tier == Compact || tier == Rail;
    }

    private function refreshTab():Void
    {
        for (buttons in [tabButtons, railTabButtons])
            for (tab => button in buttons)
                button.setClass(StyleClass.GAME_TAB_ON, tab == openTab);

        if (!hasSheet())
            return;

        var shownSheet:Box = tier == Rail ? railSheet : sheet;
        for (part in ([infoFrame, chatCard, movesCard] : Array<Component>))
            if (part.parentComponent == shownSheet)
                shownSheet.removeComponent(part, false);

        shownSheet.hidden = openTab == null;
        if (openTab != null)
            shownSheet.addComponent(switch openTab {
                case Chat: chatCard;
                case Moves: movesCard;
                case Info: infoFrame;
            });
    }

    // the bars go back to the stage, and the control row to the board, only once they've left the rail column
    private function detachParts():Void
    {
        for (part in ([infoCard, infoFrame, chatCard, movesCard, actionsCard, stage, moveStrip, peekButton, sheet, railSheet, headRow, tabRow, railTabRow] : Array<Component>))
            if (part.parentComponent != null)
                part.parentComponent.removeComponent(part, false);
        for (bar in [stage.topBar, stage.bottomBar])
            if (bar.parentComponent == railColumn)
                railColumn.removeComponent(bar, false);
        if (controls != null)
        {
            railColumn.removeComponent(controls, false);
            controls = null;
            stage.releaseControls();
        }
        for (container in [leftColumn, rightColumn, wideRow, compactColumn, railRow])
            if (container.parentComponent != null)
                container.parentComponent.removeComponent(container, false);
    }

    private function createSideColumn():VBox
    {
        var column:VBox = new VBox();
        column.width = SIDE_COLUMN_WIDTH;
        column.percentHeight = 100;
        column.addClass(StyleClass.GAME_SIDE_COLUMN);
        return column;
    }
}

package client.ui.game;

import client.datatypes.game.GameChatMessage;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

enum CompactTab
{
    Chat;
    Moves;
    Info;
}

/**
    Arranges the page's parts. Wide: info and chat | the board | moves and actions. Medium: a header
    line over the board | moves, chat and actions; the info card's facts move to the header and the
    moves card. Compact: a header line, the move strip, the board, the actions, then a chat peek with
    the Chat / Moves / Info tabs under it; an open tab shows its card in the peek's place.
**/
class GameLayout extends Box
{
    private static inline final SIDE_COLUMN_WIDTH:Float = 312;
    // until the page measures the height there is: the wide columns resolve their heights against a fixed one
    private static inline final PROVISIONAL_WIDE_HEIGHT:Float = 520;
    // medium: the moves and the chat share the column's height 3:2
    private static inline final MEDIUM_MOVES_SHARE:Float = 60;
    private static inline final MEDIUM_CHAT_SHARE:Float = 40;

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
    private final tabButtons:Map<CompactTab, Button> = [];

    private var tier:Null<BoardLayoutTier> = null;
    private var openTab:Null<CompactTab> = null;
    private var unreadCount:Int = 0;
    private var peekHeight:Float = 0; // last measured while shown: a tab hides the peek

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
        headDetailsLabel.wordWrap = true; // it wraps before the resolution would have to
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
        sheet.addClass(StyleClass.GAME_SHEET);

        tabRow = new HBox();
        tabRow.percentWidth = 100;
        tabRow.addClass(StyleClass.GAME_TABS);
        for (tab in [Chat, Moves, Info])
        {
            var button:Button = new Button();
            button.percentWidth = 100 / 3;
            button.text = LocaleUtils.localeBinding('intellector.live_game.tab.${tab.getName().toLowerCase()}');
            button.addClass(StyleClass.GAME_BUTTON);
            button.addClass(StyleClass.GAME_TAB);
            button.onClick = _ -> setOpenTab(openTab == tab ? null : tab);
            tabButtons.set(tab, button);
            tabRow.addComponent(button);
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
        actionsCard.setCompact(compact);
        movesCard.setNavigationShown(!compact);
        movesCard.setOpeningShown(tier == Medium);
        stage.setFitsHeight(!compact);
        headDetailsLabel.hidden = tier != Medium;
        headSpacer.hidden = tier == Medium;

        if (compact)
        {
            height = null;
            invalidateComponentLayout();
            for (part in [infoCard, chatCard, movesCard])
                part.percentHeight = 100;

            compactColumn.addComponent(headRow);
            compactColumn.addComponent(moveStrip);
            compactColumn.addComponent(stage);
            compactColumn.addComponent(actionsCard);
            compactColumn.addComponent(peekButton);
            compactColumn.addComponent(sheet);
            compactColumn.addComponent(tabRow);
            addComponent(compactColumn);
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

    /** Whether the board, columns and cards fit a height of their own (wide, medium) or flow (compact) **/
    public function isCompact():Bool
    {
        return tier == Compact;
    }

    /** Compact: the most the stage can take of `availableHeight` with the tabs closed (an open one scrolls the page instead); measured, so call it after a layout **/
    public function compactStageMaxHeight(availableHeight:Float):Float
    {
        if (!peekButton.hidden)
            peekHeight = peekButton.element.offsetHeight;

        var height:Float = 0;
        var partCount:Int = 0;
        for (part in compactColumn.childComponents)
        {
            if (part == sheet || (part.hidden && part != peekButton))
                continue;
            partCount++;
            if (part == peekButton)
                height += peekHeight;
            else if (part != stage)
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

    public function setOpenTab(tab:Null<CompactTab>):Void
    {
        openTab = tab;
        if (tab == Chat)
            setUnreadCount(0);
        refreshTab();
    }

    /** The latest message, for the peek; `unseen`: it counts as unread unless the chat is in view **/
    public function setLatestMessage(message:Null<GameChatMessage>, unseen:Bool):Void
    {
        peekLabel.text = message != null ? '${message.authorNickname}: ${message.text}' : LocaleUtils.localeBinding("intellector.live_game.chat.empty_peek");
        if (unseen && tier == Compact && openTab != Chat)
            setUnreadCount(unreadCount + 1);
    }

    private function setUnreadCount(count:Int):Void
    {
        unreadCount = count;
        unreadBadge.hidden = count == 0;
        unreadBadge.text = Std.string(count);
    }

    private function refreshTab():Void
    {
        for (tab => button in tabButtons)
            button.setClass(StyleClass.GAME_TAB_ON, tab == openTab);

        if (tier != Compact)
            return;

        for (part in [infoCard, chatCard, movesCard])
            if (part.parentComponent == sheet)
                sheet.removeComponent(part, false);

        peekButton.hidden = openTab != null;
        sheet.hidden = openTab == null;
        if (openTab != null)
            sheet.addComponent(switch openTab {
                case Chat: chatCard;
                case Moves: movesCard;
                case Info: infoCard;
            });
    }

    private function detachParts():Void
    {
        for (part in ([infoCard, chatCard, movesCard, actionsCard, stage, moveStrip, peekButton, sheet, headRow, tabRow] : Array<Component>))
            if (part.parentComponent != null)
                part.parentComponent.removeComponent(part, false);
        for (container in [leftColumn, rightColumn, wideRow, compactColumn])
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

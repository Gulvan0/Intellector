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
    Arranges the page's parts. Wide: info and chat | the board | moves and actions. Compact: a
    header line, the move strip, the board, the actions, then a chat peek with the Chat / Moves /
    Info tabs under it; an open tab shows its card in the peek's place.
**/
class GameLayout extends Box
{
    private static inline final SIDE_COLUMN_WIDTH:Float = 312;
    // until the page measures the height there is: the wide columns resolve their heights against a fixed one
    private static inline final PROVISIONAL_WIDE_HEIGHT:Float = 520;

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
    private final headResolutionLabel:Label;
    private final peekButton:HBox;
    private final peekLabel:Label;
    private final unreadBadge:Label;
    private final sheet:Box;
    private final tabButtons:Map<CompactTab, Button> = [];

    private var compact:Null<Bool> = null;
    private var openTab:Null<CompactTab> = null;
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
        headRow.addClass(StyleClass.GAME_COMPACT_HEAD);
        headTimeControlLabel = new Label();
        headTimeControlLabel.addClass(StyleClass.GAME_MONO);
        headTimeControlLabel.verticalAlign = "center";
        headRow.addComponent(headTimeControlLabel);
        var headSpacer:Box = new Box();
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

    public function setCompact(compact:Bool):Void
    {
        if (this.compact == compact)
            return;
        this.compact = compact;

        detachParts();
        removeAllComponents(false);

        actionsCard.setCompact(compact);
        movesCard.setNavigationShown(!compact);
        stage.setFitsHeight(!compact);

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

    /** Whether the board, columns and cards fit a height of their own (wide) or flow (compact) **/
    public function isCompact():Bool
    {
        return compact == true;
    }

    /** The compact header's time control text and resolution line **/
    public function setHeadTexts(timeControlText:Void->String, resolutionText:Void->String):Void
    {
        LocaleManager.instance.registerComponent(headTimeControlLabel, "text", timeControlText);
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
        if (unseen && compact == true && openTab != Chat)
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

        if (compact != true)
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

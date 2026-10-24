package client.ui.game;

import client.datatypes.game.GameChatEntry;
import client.datatypes.game.GameChatMessage;
import client.formatters.GameFormatters;
import client.utils.PagePaths;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.core.Component;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.KeyboardEvent;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import haxefolio.structure.ScrollArea;
import net.models.common.UserRefWithNickname;

using client.ui.ComponentExtension;

/** The game's chat: messages, newest at the bottom, and a line to write one **/
class ChatCard extends VBox
{
    private static inline final MAX_MESSAGE_LENGTH:Int = 255;
    private static inline final ENTER_KEY_CODE:Int = 13;
    // within this distance of the bottom, a new message keeps the view at the bottom
    private static inline final STICK_TO_BOTTOM_PX:Float = 24;

    private final spectatorStrip:SpectatorStrip;
    private final messageList:VBox;
    private final scrollArea:ScrollArea;
    private final input:TextField;
    private final sendButton:Button;
    private final onSend:String->Void;

    /** `onSend`: called with a trimmed, non-empty message; the draft is cleared with `clearDraft` **/
    public function new(onSend:String->Void)
    {
        super();
        this.onSend = onSend;
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_CHAT_CARD);

        spectatorStrip = new SpectatorStrip();
        spectatorStrip.hidden = true;
        addComponent(spectatorStrip);

        messageList = new VBox();
        messageList.percentWidth = 100;
        messageList.addClass(StyleClass.GAME_CHAT_MESSAGES);

        scrollArea = new ScrollArea(messageList);
        scrollArea.percentHeight = 100;
        addComponent(scrollArea);

        var sendRow:HBox = new HBox();
        sendRow.percentWidth = 100;
        sendRow.addClass(StyleClass.GAME_CHAT_SEND_ROW);
        addComponent(sendRow);

        input = new TextField();
        input.percentWidth = 100;
        input.maxChars = MAX_MESSAGE_LENGTH;
        input.placeholder = LocaleUtils.localeBinding("intellector.live_game.chat.placeholder");
        input.onChange = _ -> refreshSendButton();
        input.registerEvent(KeyboardEvent.KEY_DOWN, onInputKeyDown);
        sendRow.addComponent(input);

        sendButton = new Button();
        sendButton.text = LocaleUtils.localeBinding("intellector.live_game.chat.send");
        sendButton.addClass(StyleClass.GAME_BUTTON);
        sendButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        sendButton.onClick = _ -> send();
        sendRow.addComponent(sendButton);

        refreshSendButton();
    }

    /** `guestCount` spectators are unauthenticated and so have no nickname; null `spectators` hides the strip **/
    public function setSpectators(spectators:Null<Array<UserRefWithNickname>>, guestCount:Int):Void
    {
        spectatorStrip.hidden = spectators == null;
        if (spectators != null)
            spectatorStrip.setSpectators(spectators, guestCount);
    }

    public function setEntries(entries:Array<GameChatEntry>):Void
    {
        messageList.removeAllComponents();
        for (entry in entries)
            messageList.addComponent(createEntry(entry));
        scrollToBottom();
    }

    public function appendEntry(entry:GameChatEntry):Void
    {
        var nativeElement:js.html.Element = scrollArea.element;
        var atBottom:Bool = nativeElement.scrollHeight - nativeElement.scrollTop - nativeElement.clientHeight <= STICK_TO_BOTTOM_PX;

        messageList.addComponent(createEntry(entry));
        if (atBottom)
            scrollToBottom();
    }

    public function clearDraft():Void
    {
        input.text = "";
        refreshSendButton();
    }

    private function createEntry(entry:GameChatEntry):Component
    {
        return switch entry {
            case Message(message): createMessage(message);
            case Offer(action, kind, author): createLogLine(GameFormatters.offerLogLine(action, kind, author));
            case TimeAdded(receiver, amountSeconds): createLogLine(GameFormatters.timeAddedLogLine(receiver, amountSeconds));
            case Ended(outcome): createLogLine(GameFormatters.outcomeLogLine(outcome));
        }
    }

    private function createLogLine(text:String):Label
    {
        var line:Label = new Label();
        line.percentWidth = 100;
        line.text = text;
        line.addClass(StyleClass.GAME_CHAT_LOG);
        return line;
    }

    private function createMessage(message:GameChatMessage):VBox
    {
        var entry:VBox = new VBox();
        entry.percentWidth = 100;
        entry.addClass(StyleClass.GAME_CHAT_MESSAGE);

        var authorRow:HBox = new HBox();
        entry.addComponent(authorRow);

        var authorLabel:Label = new Label();
        authorLabel.text = message.authorNickname;
        authorLabel.addClass(StyleClass.GAME_NICKNAME);
        authorLabel.setClass(StyleClass.GAME_NICKNAME_LINK, !StringTools.startsWith(message.authorRef, "_"));
        PageLink.attach(authorLabel, PagePaths.playerProfile(message.authorRef));
        authorRow.addComponent(authorLabel);

        if (message.spectator)
        {
            var spectatorLabel:Label = new Label();
            spectatorLabel.text = LocaleUtils.localeBinding("intellector.live_game.chat.spectator");
            spectatorLabel.addClass(StyleClass.GAME_HINT);
            spectatorLabel.verticalAlign = "center";
            authorRow.addComponent(spectatorLabel);
        }

        var textLabel:Label = new Label();
        textLabel.percentWidth = 100;
        textLabel.text = message.text;
        textLabel.addClass(StyleClass.GAME_CHAT_TEXT);
        textLabel.setClass(StyleClass.GAME_CHAT_TEXT_SPECTATOR, message.spectator);
        entry.addComponent(textLabel);

        return entry;
    }

    private function onInputKeyDown(event:KeyboardEvent):Void
    {
        if (event.keyCode == ENTER_KEY_CODE)
            send();
    }

    private function send():Void
    {
        var text:String = StringTools.trim(input.text ?? "");
        if (text != "")
            onSend(text);
    }

    private function refreshSendButton():Void
    {
        sendButton.disabled = StringTools.trim(input.text ?? "") == "";
    }

    private function scrollToBottom():Void
    {
        Toolkit.callLater(() -> {
            scrollArea.element.scrollTop = scrollArea.element.scrollHeight;
        });
    }
}

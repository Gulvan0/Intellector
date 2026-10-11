package client.ui.game;

import client.datatypes.game.GameChatMessage;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.KeyboardEvent;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;

using client.ui.ComponentExtension;

/** The game's chat: messages, newest at the bottom, and a line to write one **/
class ChatCard extends VBox
{
    private static inline final MAX_MESSAGE_LENGTH:Int = 255;
    private static inline final ENTER_KEY_CODE:Int = 13;
    // within this distance of the bottom, a new message keeps the view at the bottom
    private static inline final STICK_TO_BOTTOM_PX:Float = 24;

    private final messageList:VBox;
    private final scrollArea:ScrollArea;
    private final input:TextField;
    private final sendButton:Button;
    private final onSend:String->Void;
    private final onAuthorClicked:GameChatMessage->Void;

    /** `onSend`: called with a trimmed, non-empty message; the draft is cleared with `clearDraft` **/
    public function new(onSend:String->Void, onAuthorClicked:GameChatMessage->Void)
    {
        super();
        this.onSend = onSend;
        this.onAuthorClicked = onAuthorClicked;
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_CHAT_CARD);

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

    public function setMessages(messages:Array<GameChatMessage>):Void
    {
        messageList.removeAllComponents();
        for (message in messages)
            messageList.addComponent(createMessage(message));
        scrollToBottom();
    }

    public function appendMessage(message:GameChatMessage):Void
    {
        var nativeElement:js.html.Element = scrollArea.element;
        var atBottom:Bool = nativeElement.scrollHeight - nativeElement.scrollTop - nativeElement.clientHeight <= STICK_TO_BOTTOM_PX;

        messageList.addComponent(createMessage(message));
        if (atBottom)
            scrollToBottom();
    }

    public function clearDraft():Void
    {
        input.text = "";
        refreshSendButton();
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
        authorLabel.onClick = _ -> onAuthorClicked(message);
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

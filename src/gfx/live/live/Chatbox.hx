package gfx.live.live;

import gfx.live.interfaces.IReadOnlyGameRelatedModel;
import haxe.ui.core.Component;
import gfx.live.events.ModelUpdateEvent;
import gfx.live.models.ReadOnlyModel;
import gfx.live.interfaces.IGameScreen;
import gfx.live.events.ChatboxEvent;
import gfx.live.interfaces.IGameComponent;
import haxe.ui.core.Platform;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import net.Requests;
import haxe.ui.styles.Style;
import utils.StringUtils;
import dict.Phrase;
import gfx.game.GameActionBar.ActionBtn;
import net.shared.Outcome;
import serialization.GameLogParser;
import net.INetObserver;
import haxe.ui.containers.VBox;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import dict.Dictionary;
import dict.Utils;
import haxe.ui.components.HorizontalScroll;
import haxe.Timer;
import haxe.ui.components.VerticalScroll;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen as HaxeUIScreen;

using StringTools;
using gfx.live.models.CommonModelExtractors;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/live/chatbox.xml'))
class Chatbox extends VBox implements IGameComponent
{
    private var eventHandler:ChatboxEvent->Void;

    public function init(model:ReadOnlyModel, gameScreen:IGameScreen)
    {
        this.eventHandler = gameScreen.handleChatboxEvent;

        var history:Array<ChatEntry> = model.asGameModel().getChatHistory();

        for (entry in history)
            appendEntry(entry);

        switch model 
        {
            case MatchVersusPlayer(model):
                if (model.hasEnded())
                    inputBox.disabled = true;
            case MatchVersusBot(model):
                inputBox.hidden = true;
            case Spectation(model):
                if (model.hasEnded())
                    inputBox.disabled = true;
            default:
        }

        HaxeUIScreen.instance.registerEvent(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        switch event 
        {
            case EntryAddedToChatHistory:
                var lastEntry = model.asGameModel().getLastChatEntry();
                if (lastEntry != null)
                    appendEntry(lastEntry);
            case GameEnded:
                inputBox.disabled = true;
            default:
        }
    }

    public function destroy()
    {
        HaxeUIScreen.instance.unregisterEvent(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    public function asComponent():Component
    {
        return this;
    }

    private function appendEntry(entry:ChatEntry)
    {
        switch entry 
        {
            case PlayerMessage(playerRef, messageText):
                appendMessage(playerRef, messageText, true);
            case SpectatorMessage(playerRef, messageText):
                appendMessage(playerRef, messageText, false);
            case Log(phrase):
                appendLog(Dictionary.getPhrase(phrase));
        }
    }

    private function appendMessage(authorRef:String, text:String, isNotFromSpectator:Bool) 
    {
        var guestAuthorStyle:Style = {fontBold: true, fontItalic: !isNotFromSpectator};
        var normalAuthorStyle:Style = {fontBold: true, fontItalic: !isNotFromSpectator, pointerEvents: 'true', backgroundColor: 0, backgroundOpacity: 0, cursor: 'pointer'};
        var hoverAuthorStyle:Style = normalAuthorStyle.clone();
        hoverAuthorStyle.color = 0x428fd8;

        var authorLabel:Label = new Label();
        authorLabel.percentWidth = 100;
        authorLabel.text = Utils.playerRef(authorRef);

        if (authorRef.charAt(0) != "_")
        {
            authorLabel.customStyle = normalAuthorStyle;
            authorLabel.onMouseOver = e -> {
                authorLabel.customStyle = hoverAuthorStyle;
            };
            authorLabel.onMouseOut = e -> {
                authorLabel.customStyle = normalAuthorStyle;
            };
            authorLabel.onClick = e -> {
                Requests.getMiniProfile(authorRef);
            };
        }
        else
            authorLabel.customStyle = guestAuthorStyle;

        var textLabel:Label = new Label();
        textLabel.percentWidth = 100;
        textLabel.text = text;
        textLabel.customStyle = {fontItalic: !isNotFromSpectator};

        history.addComponent(authorLabel);
        history.addComponent(textLabel);
        Timer.delay(scrollToMax, 50);
    }

    private function appendLog(text:String) 
    {
        var label:Label = new Label();
        label.percentWidth = 100;
        label.text = text;
        label.customStyle = {fontItalic: true, textAlign: 'center'};

        history.addComponent(label);
        Timer.delay(scrollToMax, 50);
    }

    private function scrollToMax() 
    {
        var vscroll = history.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.max;
    }

    private function onKeyPress(e:KeyboardEvent) 
    {
        if (e.keyCode == Platform.instance.KeyEnter || e.keyCode == 108) //108 is numpad enter
            if (messageInput.focus)
                send();
    }

    @:bind(sendBtn, MouseEvent.CLICK)
    private function onSendBtnPressed(e)
    {
        send();
    }

    private function send() 
    {
        var ownRef:String = LoginManager.getRef();
        var text = StringUtils.clean(messageInput.text, 500);

        messageInput.text = "";

        if (text != "")
            eventHandler(MessageSent(text));
    }

    public function new() 
    {
        super();
    }
}
package gfx;

import haxe.ui.containers.Box;
import openfl.Assets;
import js.Browser;
import gfx.popups.LogIn;
import gfx.popups.Settings;
import utils.MathUtils;
import haxe.ui.containers.ScrollView;
import utils.Changelog;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.Timer;
import haxe.ui.util.Variant;
import openfl.display.Shape;
import gameboard.Piece;
import haxe.ui.components.Image;
import openfl.events.Event;
import utils.AssetManager;
import dict.Phrase;
import haxe.ui.components.OptionBox;
import dict.Dictionary;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import struct.PieceColor;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import struct.PieceType;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialogs as DialogManager;
import haxe.ui.core.Screen;
import gfx.basic_components.SpriteWrapper;

enum SpaceRemoval
{
    None;
    Trim;
    All;
}

class Dialogs
{
    private static var shownDialogs:Array<Dialog> = [];

    private static function correctDialogPosition(dialog:Dialog)
    {
        dialog.x = (Screen.instance.actualWidth - dialog.width) / 2;
        dialog.y = (Screen.instance.actualHeight - dialog.height) / 2;
        trace(Screen.instance.actualWidth, Screen.instance.actualHeight, dialog.width, dialog.height, dialog.x, dialog.y);
    }

    public static function onScreenResized() 
    {
        Timer.delay(() -> {
            for (dialog in shownDialogs)
                correctDialogPosition(dialog);
        }, 40);
    }

    public static function hasActiveDialog():Bool
    {
        return !Lambda.empty(shownDialogs);
    }

    private static function onDialogClosed(e:DialogEvent, dialog:Dialog, ?customCloseHandler:DialogEvent->Void)
    {
        shownDialogs.remove(dialog);
        if (customCloseHandler != null)
            customCloseHandler(e);
        if (hasActiveDialog())
            shownDialogs[0].disabled = false;
    }

    private static function addDialog(dialog:Dialog, show:Bool, ?customCloseHandler:DialogEvent->Void, ?modal:Bool)
    {
        if (hasActiveDialog())
            shownDialogs[0].disabled = true;
        shownDialogs.unshift(dialog);
        dialog.onDialogClosed = onDialogClosed.bind(_, dialog, customCloseHandler);
        if (show)
            dialog.showDialog(modal);
        Timer.delay(correctDialogPosition.bind(dialog), 40);
    }

    public static function alertRaw(message:String, ?title:String = "Raw alert")
    {
        addDialog(DialogManager.messageBox(message, title, MessageBoxType.TYPE_WARNING, true), false);
    }

    public static function alert(message:Phrase, title:Phrase, ?messageSubstitutions:Array<String>)
    {
        var messageStr:String = Dictionary.getPhrase(message, messageSubstitutions);
        var titleStr:String = Dictionary.getPhrase(title);
        addDialog(DialogManager.messageBox(messageStr, titleStr, MessageBoxType.TYPE_WARNING, true), false);
    }

    public static function alertCallback(message:Phrase, title:Phrase):Void->Void 
    {
        return alert.bind(message, title);
    }

    public static function info(message:Phrase, title:Phrase, ?messageSubstitutions:Array<String>)
    {
        addDialog(DialogManager.messageBox(Dictionary.getPhrase(message, messageSubstitutions), Dictionary.getPhrase(title), MessageBoxType.TYPE_INFO, true), false);
    }

    public static function confirmRaw(message:String, title:String, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        var dialog = DialogManager.messageBox(message, title, MessageBoxType.TYPE_QUESTION, true);

        addDialog(dialog, false, (e:DialogEvent) -> {
            if (e.button == DialogButton.YES)
                onConfirmed();
            else
                onDeclined();
        });
    }

    public static function confirm(message:Phrase, title:Phrase, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        confirmRaw(Dictionary.getPhrase(message), Dictionary.getPhrase(title), onConfirmed, onDeclined);
    }

    public static function prompt(message:Phrase, removeSpaces:SpaceRemoval, onInput:String->Void, ?onCancel:Null<Void->Void>, ?emptyIsCancel:Bool = true) 
    {
        var res:Null<String> = Browser.window.prompt(Dictionary.getPhrase(message));

        if (removeSpaces == Trim)
            res = StringTools.trim(res);
        else if (removeSpaces == All)
            res = StringTools.replace(res, ' ', '');

        if (res != null && (res != "" || !emptyIsCancel))
            onInput(res);
        else if (onCancel != null)
            onCancel();
    }

    public static function custom(dialog:Dialog, modal:Bool = true, ?onClosed:DialogEvent->Void)
    {
        addDialog(dialog, true, onClosed, modal);
    }

    /**
        Displays non-closable reconnection pop-up
        @returns Callback closing the dialog
    **/
    public static function reconnectionDialog():Void->Void
    {
        var loadingAnimation:SpriteWrapper = new SpriteWrapper(Assets.getMovieClip("preloader:LogoPreloader"), false);
        loadingAnimation.x = 120;
        loadingAnimation.y = 132;

        var box:Box = new Box();
        box.width = 240;
        box.height = 264;
        box.horizontalAlign = 'center';
        box.addComponent(loadingAnimation);

        var label:Label = new Label();
        label.customStyle = {fontSize: 14, fontItalic: true};
        label.text = Dictionary.getPhrase(RECONNECTION_POP_UP_TEXT);
        label.horizontalAlign = 'center';

        var vbox:VBox = new VBox();
        vbox.verticalAlign = 'center';
        vbox.addComponent(box);
        vbox.addComponent(label);

        var dialog:Dialog = new Dialog();
        dialog.title = Dictionary.getPhrase(RECONNECTION_POP_UP_TITLE);
        dialog.closable = false;
        dialog.addComponent(vbox);
        addDialog(dialog, true, null, true);
        return () -> {dialog.hideDialog(null);};
    }

    public static function branchingHelp()
    {
        var messageBox = new MessageBox();
        messageBox.type = MessageBoxType.TYPE_INFO;
        messageBox.title = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TITLE);
        messageBox.messageLabel.htmlText = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TEXT);
        messageBox.messageLabel.customStyle = {fontSize: Math.max(Screen.instance.actualHeight * 0.02, 12)};
        messageBox.width = Math.min(500, Screen.instance.actualWidth * 0.95);
        addDialog(messageBox, true, null, true);
    }

    public static function changelog()
    {
        var changesLabel:Label = new Label();
        changesLabel.htmlText = Changelog.getAll();
        changesLabel.customStyle = {fontSize: MathUtils.clamp(0.025 * Screen.instance.actualHeight, 12, 36)};

        var changesSV:ScrollView = new ScrollView();
        changesSV.width = Math.min(1000, 0.9 * Screen.instance.actualWidth);
        changesSV.height = Math.min(450, 0.7 * Screen.instance.actualHeight);
        changesSV.horizontalAlign = 'center';
        changesSV.verticalAlign = 'center';
        changesSV.addComponent(changesLabel);

        var dialog:Dialog = new Dialog();
        dialog.title = Dictionary.getPhrase(CHANGELOG_DIALOG_TITLE);
        dialog.addComponent(changesSV);

        addDialog(dialog, true, null, false);
    }

    public static function settings()
    {
        var dialog:Settings = new Settings();
        addDialog(dialog, true, dialog.onClose, false);
    }

    public static function login(?onLoggedIn:Void->Void)
    {
        var dialog:LogIn = new LogIn();
        addDialog(dialog, true, event -> {
            if (onLoggedIn != null && event.button == DialogButton.OK)
                onLoggedIn();
        }, false);
    }

    public static function promotionSelect(color:PieceColor, callback:PieceType->Void)
    {
        function cb(dialog:Dialog, type:PieceType) 
        {
            dialog.hideDialog(DialogButton.OK);
            callback(type);
        }

        var dialog:Dialog = new Dialog();
        var body:VBox = new VBox();

        var question:Label = new Label();
        question.text = Dictionary.getPhrase(PROMOTION_DIALOG_QUESTION);
        question.textAlign = "center";
        body.addComponent(question);

        var btns:HBox = new HBox();
        btns.horizontalAlign = 'center';
        for (type in [Aggressor, Liberator, Defensor, Dominator])
            btns.addComponent(pieceBtn(type, color, cb.bind(dialog, type)));
        body.addComponent(btns);

        dialog.addComponent(body);
        dialog.title = Dictionary.getPhrase(PROMOTION_DIALOG_TITLE);
        dialog.buttons = DialogButton.CANCEL;
        addDialog(dialog, true, null, false);
    }

    public static function chameleonConfirm(onDecided:Bool->Void)
    {
        var dialog = DialogManager.messageBox(Dictionary.getPhrase(CHAMELEON_DIALOG_QUESTION), Dictionary.getPhrase(CHAMELEON_DIALOG_TITLE), MessageBoxType.TYPE_QUESTION, false);
        addDialog(dialog, false, e -> {
            if (e.button == DialogButton.YES)
                onDecided(true);
            else if (e.button == DialogButton.NO)
                onDecided(false);
        });
    }

    public static function specifyChallengeParams()
    {
        //TODO: Fill
    }

    private static function onBtnAdded(btn:Button, type:PieceType, color:PieceColor, iconSize:Float, e) 
    {
        var icon:Image = btn.findComponent(Image);
        switch type 
        {
            case Progressor:
                icon.width = Piece.pieceRelativeScale(Progressor) * iconSize;
                icon.height = icon.width / Piece.pieceAspectRatio(Progressor, color);
            default:
                icon.height = Piece.pieceRelativeScale(type) * iconSize;
                icon.width = icon.height * Piece.pieceAspectRatio(type, color);
        }
    }

    private static function pieceBtn(type:PieceType, color:PieceColor, callback:Void->Void):Button
    {
        var btnSize:Float = Math.min(100, Math.min(Screen.instance.actualHeight * 0.5, Screen.instance.actualWidth * 0.2));

        var btn:Button = new Button();
        btn.icon = AssetManager.piecePath(type, color);
        btn.width = btnSize;
        btn.height = btnSize;
        btn.addEventListener(Event.ADDED_TO_STAGE, onBtnAdded.bind(btn, type, color, 0.8 * btnSize));
        btn.onClick = (e) -> {callback();};
        return btn;
    }
}
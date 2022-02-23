package gfx.screens;

import dict.Phrase;
import net.ServerEvent;
import net.LoginManager;
import js.Cookie;
import js.Browser;
import haxe.Timer;
import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.components.CheckBox;
import dict.Dictionary;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
import url.Utils;

class SignIn extends Sprite
{
	private static var menuWidth:Float = 200;
	
	private var loginField:TextField;
	private var passField:TextField;
	private var rememberMe:CheckBox;
	private var errorLabel:Label;

	private var fadeTimer:Null<Timer>;

	private function displayLoginError(?text:String)
	{
		if (fadeTimer != null)
			fadeTimer.stop();

		if (text != null)
			errorLabel.text = text;
		errorLabel.alpha = 1;

		fadeTimer = new Timer(20);
		fadeTimer.run = () -> {
			errorLabel.alpha -= 0.01;
			if (errorLabel.alpha == 0)
			{
				fadeTimer.stop();
				fadeTimer = null;
			}
		}
	}

	private function onSignInPressed()
	{
		LoginManager.signin(loginField.text, passField.text, false);
	}

	private function onRegisterPressed()
	{
		LoginManager.register(loginField.text, passField.text);
	}

	private function onEntranceResults(success:Bool, failMessage:Phrase)
	{
		if (success)
			Utils.saveLoginDetails(!rememberMe.selected);
		else
			displayLoginError(Dictionary.getPhrase(failMessage));
	}

	public function handleNetEvent(event:ServerEvent)
	{
		switch event 
		{
			case LoginResult(success):
				onEntranceResults(success, INVALID_PASSWORD);
			case RegisterResult(success):
				onEntranceResults(success, ALREADY_REGISTERED);
			case ReconnectionNeeded(match_id, whiteLogin, blackLogin, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
				//TODO: Uncomment
				//ScreenManager.toScreen(new OnlineGame(match_id, whiteLogin, blackLogin, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog));
			default:
		}
	}

    public function new() 
    {
        super();
        var signinMenu = new VBox();
		signinMenu.width = menuWidth;

		loginField = makeInputField(menuWidth, Dictionary.getPhrase(LOGIN_FIELD_TITLE), "A-Za-z0-9");
		signinMenu.addComponent(loginField);

		passField = makeInputField(menuWidth, Dictionary.getPhrase(PASSWORD_FIELD_TITLE), "A-Za-z0-9", true);
		signinMenu.addComponent(passField);

		rememberMe = createRememberMe();
		signinMenu.addComponent(rememberMe);

		var btns:HBox = createButtonBox();
		signinMenu.addComponent(btns);

		errorLabel = makeLabel("", false, menuWidth, "center");
		errorLabel.alpha = 0;
		signinMenu.addComponent(errorLabel);

		signinMenu.x = (Browser.window.innerWidth - menuWidth) / 2;
		signinMenu.y = 100;
		addChild(signinMenu);    
	}
	
	private function createRememberMe():CheckBox
	{
		var rememberMe = new CheckBox();
		rememberMe.selected = false;
		rememberMe.text = Dictionary.getPhrase(REMEMBER_ME_CHECKBOX_TITLE);
		rememberMe.horizontalAlign = 'center';
		return rememberMe;
	}

	private function createButtonBox():HBox
	{
		var btns:HBox = new HBox();
		btns.horizontalAlign = "center";
		btns.addComponent(createBtn(SIGN_IN_BTN, onSignInPressed));
		btns.addComponent(createBtn(REGISTER_BTN, onRegisterPressed));
		return btns;
	}
	
	private function createBtn(phrase:Phrase, callback:Void->Void):Button
	{
		var btn = new Button();
		btn.text = Dictionary.getPhrase(phrase);
		btn.width = menuWidth / 2 - 5;

		btn.onClick = (e) -> 
		{
			if (loginField.text == "" || passField.text == "" || loginField.text == null || passField.text == null)
				displayLoginError(Dictionary.getPhrase(SPECIFY_BOTH_REG_ERROR));
			else
				callback();
		}

		return btn;
	}

	private static function makeLabel(text:String, ?isHTML:Bool = false, ?width:Float, ?textAlign:String = "left"):Label
    {
        var label:Label = new Label();
        if (isHTML)
            label.htmlText = text;
        else
            label.text = text;
        if (width != null)
            label.width = width;
        label.textAlign = textAlign;
        return label;
    }

    private static function makeInputField(width:Float, ?placeholder:String, ?restrictChars:String, ?password:Bool = false):TextField
    {
        var tf = new TextField();
        tf.width = width;
        if (placeholder != null)
		    tf.placeholder = placeholder;
        if (restrictChars != null)
            tf.restrictChars = restrictChars;
        tf.password = password;
        return tf;
    }
}
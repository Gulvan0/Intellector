package gfx.screens;

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

enum ServerEntranceType
{
	LogIn;
	Register;
}

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
		var onResults:String->Void = onEntranceResults.bind(LogIn, loginField.text, passField.text, rememberMe.selected);
		Networker.signin(loginField.text, passField.text, onResults);
	}

	private function onRegisterPressed()
	{
		var onResults:String->Void = onEntranceResults.bind(Register, loginField.text, passField.text, rememberMe.selected);
		Networker.register(loginField.text, passField.text, onResults);
	}

	private function onEntranceResults(type:ServerEntranceType, login:String, password:String, remember:Bool, result:String)
	{
		if (result == 'success')
		{
			if (remember)
				url.Utils.saveLoginDetails(login, password);
			ScreenManager.instance.toMain();
		}
		else
		{
			if (type == LogIn)
				if (result == 'online')
					displayLoginError(Dictionary.getPhrase(ALREADY_LOGGED));
				else
					displayLoginError(Dictionary.getPhrase(INVALID_PASSWORD));
			else
				displayLoginError(Dictionary.getPhrase(ALREADY_REGISTERED));
		}
	}

    public function new() 
    {
        super();
        var signinMenu = new VBox();
		signinMenu.width = menuWidth;

		loginField = Factory.makeInputField(menuWidth, Dictionary.getPhrase(LOGIN_FIELD_TITLE), "A-Za-z0-9");
		signinMenu.addComponent(loginField);

		passField = Factory.makeInputField(menuWidth, Dictionary.getPhrase(PASSWORD_FIELD_TITLE), "A-Za-z0-9", true);
		signinMenu.addComponent(passField);

		rememberMe = createRememberMe();
		signinMenu.addComponent(rememberMe);

		var btns:HBox = createButtonBox();
		signinMenu.addComponent(btns);

		errorLabel = Factory.makeLabel("", false, menuWidth, "center");
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
		btns.addComponent(createBtn(LogIn));
		btns.addComponent(createBtn(Register));
		return btns;
	}
	
	private function createBtn(type:ServerEntranceType):Button
	{
		var btn = new Button();
		btn.text = Dictionary.getPhrase(type == LogIn? SIGN_IN_BTN : REGISTER_BTN);
		btn.width = menuWidth / 2 - 5;

		btn.onClick = (e) -> 
		{
			if (loginField.text == "" || passField.text == "" || loginField.text == null || passField.text == null)
				displayLoginError(Dictionary.getPhrase(SPECIFY_BOTH_REG_ERROR));
			else if (type == LogIn)
				onSignInPressed();
			else
				onRegisterPressed();
		}

		return btn;
	}
}
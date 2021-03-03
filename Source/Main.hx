package;

import haxe.Timer;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import openfl.system.Capabilities;
import haxe.ui.Toolkit;
import openfl.display.SimpleButton;
import js.Browser;
import openfl.display.Sprite;

class Main extends Sprite
{

	private var signinMenu:VBox;
	private var mainMenu:VBox;
	private var gameboard:Field;

	private var errorLabel:Label;
	private var fadeTimer:Null<Timer>;

	public function new()
	{
		super();
		Toolkit.init();
		Figure.initFigures();
		Networker.connect();
		drawSigninMenu();
	}

	private function onLoginResults(result:String)
	{
		if (result == 'success')
		{
			removeChild(signinMenu);
			trace("Hooray");
			drawMainMenu();
		}
		else 
			displayLoginError();
	}

	private function drawSigninMenu() 
	{
		signinMenu = new VBox();

		var loginField = new haxe.ui.components.TextField();
		loginField.placeholder = "Login";
		signinMenu.addComponent(loginField);

		var passField = new haxe.ui.components.TextField();
		passField.placeholder = "Password";
		signinMenu.addComponent(passField);

		var signinbtn = new haxe.ui.components.Button();
		signinbtn.text = "Sign In";
		signinMenu.addComponent(signinbtn);

		signinbtn.onClick = (e) -> {
			Networker.signin(loginField.text, passField.text, onLoginResults);
		}

		errorLabel = new haxe.ui.components.Label();
		errorLabel.text = "Invalid login/password";
		errorLabel.alpha = 0;
		signinMenu.addComponent(errorLabel);

		signinMenu.x = 100;
		signinMenu.y = 100;
		addChild(signinMenu);
	}

	private function drawMainMenu() 
	{

	}

	private function displayLoginError()
	{
		if (fadeTimer != null)
			fadeTimer.stop();

		errorLabel.alpha = 1;

		fadeTimer = new Timer(10);
		fadeTimer.run = () -> {
			errorLabel.alpha--;
			if (errorLabel.alpha == 0)
			{
				fadeTimer.stop();
				fadeTimer = null;
			}
		}
	}

	private function drawGame() 
	{
		gameboard = new Field();
		gameboard.x = 200;
		gameboard.y = 100;
		addChild(gameboard);	
	}
}

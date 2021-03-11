package;

import openfl.Assets;
import Networker.GameOverData;
import Networker.MoveData;
import Networker.BattleData;
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

	private function onSignResults(signin:Bool, result:String)
	{
		if (result == 'success')
		{
			removeChild(signinMenu);
			Networker.registerChallengeReceiver(drawGame);
			drawMainMenu();
		}
		else
		{
			errorLabel.text = signin? "Invalid login/password" : "An user with this login already exists";
			displayLoginError();
		}
	}

	private function drawSigninMenu() 
	{
		signinMenu = new VBox();
		signinMenu.width = 200;

		var loginField = new haxe.ui.components.TextField();
		loginField.placeholder = "Login";
		loginField.width = 200;
		loginField.restrictChars = "A-Za-z0-9";
		signinMenu.addComponent(loginField);

		var passField = new haxe.ui.components.TextField();
		passField.placeholder = "Password";
		passField.width = loginField.width;
		passField.restrictChars = "A-Za-z0-9";
		passField.password = true;
		signinMenu.addComponent(passField);

		var btns:HBox = new HBox();
		btns.horizontalAlign = "center";

		var signinbtn = new haxe.ui.components.Button();
		signinbtn.text = "Sign In";
		signinbtn.width = loginField.width / 2 - 5;
		btns.addComponent(signinbtn);

		signinbtn.onClick = (e) -> {
			Networker.signin(loginField.text, passField.text, onSignResults.bind(true));
		}

		var regbtn = new haxe.ui.components.Button();
		regbtn.text = "Register";
		regbtn.width = loginField.width / 2 - 5;
		btns.addComponent(regbtn);

		regbtn.onClick = (e) -> {
			Networker.register(loginField.text, passField.text, onSignResults.bind(false));
		}
		
		signinMenu.addComponent(btns);

		errorLabel = new haxe.ui.components.Label();
		errorLabel.text = "Invalid login/password";
		errorLabel.alpha = 0;
		signinMenu.addComponent(errorLabel);

		signinMenu.x = (Browser.window.innerWidth - signinMenu.width) / 2;
		signinMenu.y = 100;
		addChild(signinMenu);
	}

	private function drawMainMenu() 
	{
		mainMenu = new VBox();
		mainMenu.width = 200;

		var calloutBtn = new haxe.ui.components.Button();
		calloutBtn.width = 200;
		calloutBtn.text = "Send challenge";
		mainMenu.addComponent(calloutBtn);

		calloutBtn.onClick = (e) -> {
			var response = Browser.window.prompt("Enter the callee's username");

			if (response != null)
				Networker.sendChallenge(response, drawGame);
		}

		mainMenu.x = (Browser.window.innerWidth - mainMenu.width) / 2;
		mainMenu.y = 100;
		addChild(mainMenu);
	}

	private function displayLoginError()
	{
		if (fadeTimer != null)
			fadeTimer.stop();

		errorLabel.alpha = 1;

		fadeTimer = new Timer(10);
		fadeTimer.run = () -> {
			errorLabel.alpha -= 0.01;
			if (errorLabel.alpha == 0)
			{
				fadeTimer.stop();
				fadeTimer = null;
			}
		}
	}

	private function drawGame(data:BattleData) 
	{
		Networker.registerGameEvents(onMove, onEnded);
		removeChild(mainMenu);
		gameboard = new Field(data.colour);
		gameboard.x = 200;
		gameboard.y = 100;
		addChild(gameboard);
		Assets.getSound("sounds/notify.mp3").play();	
	}

	private function onMove(data:MoveData) 
	{
		gameboard.move(data.fromI, data.fromJ, data.toI, data.toJ);
	}

	private function onEnded(data:GameOverData) 
	{
		Networker.unregisterGameEvents(drawGame);
		var resultMessage;
		if (data.winner_color == "")
			resultMessage = "½ - ½.";
		else if (data.winner_color == gameboard.playerColor.getName().toLowerCase())
			if (data.reason == 'mate')
				resultMessage = "You won.";
			else 
				resultMessage = "Opponent disconnected. You won.";
		else
			resultMessage = "You lost.";
		Assets.getSound("sounds/notify.mp3").play();
		Browser.alert("Game over. " + resultMessage);
		removeChild(gameboard);
		addChild(mainMenu);
	}
}

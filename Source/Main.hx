package;

import Figure.FigureColor;
import Networker.TimeData;
import js.html.URLSearchParams;
import js.Cookie;
import Figure.FigureType;
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
	private var joinMenu:VBox;
	private var gameboard:Field;
	public static var sidebox:Sidebox;

	private var errorLabel:Label;
	private var fadeTimer:Null<Timer>;

	public function new()
	{
		super();
		Toolkit.init();
		Figure.initFigures();
		Networker.connect(drawGame);
		var searcher = new URLSearchParams(Browser.location.search);
		if (Cookie.exists("saved_login") && Cookie.exists("saved_password"))
			Networker.signin(Cookie.get("saved_login"), Cookie.get("saved_password"), onAutologinResults);
		else if (searcher.has("id"))
			Networker.getGame(Std.parseInt(searcher.get("id")), drawJoinGame, (s)->{drawSigninMenu();}, drawMainMenu);
		else
			drawSigninMenu();
	}

	private function onAutologinResults(result:String)
	{
		if (result == 'success')
		{
			var searcher = new URLSearchParams(Browser.location.search);
			if (searcher.has("id"))
				Networker.getGame(Std.parseInt(searcher.get("id")), drawJoinGame, (s)->{drawMainMenu();}, drawMainMenu);
			else
				drawMainMenu();
		}
		else
		{
			Cookie.remove("saved_login");
			Cookie.remove("saved_password");
			drawSigninMenu();
		}
	}

	private function onSignResults(signin:Bool, result:String)
	{
		if (result == 'success')
		{
			removeChild(signinMenu);
			drawMainMenu();
		}
		else
		{
			if (!signin)
				errorLabel.text = "An user with this login already exists";
			else if (result == 'online')
				errorLabel.text = "An user with this login is already online";
			else
				errorLabel.text = "Invalid login/password";
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
		Browser.window.history.pushState({}, "Intellector", "");
		Networker.registerMainMenuEvents();

		mainMenu = new VBox();
		mainMenu.width = 200;

		var calloutBtn = new haxe.ui.components.Button();
		calloutBtn.width = 200;
		calloutBtn.text = "Send challenge";
		mainMenu.addComponent(calloutBtn);

		calloutBtn.onClick = (e) -> {
			var response = Browser.window.prompt("Enter the callee's username");

			if (response != null)
				Networker.sendChallenge(response);
		}

		mainMenu.x = (Browser.window.innerWidth - mainMenu.width) / 2;
		mainMenu.y = 100;
		addChild(mainMenu);
	}

	private function drawJoinGame(enemy:String) 
	{
		joinMenu = new VBox();
		joinMenu.width = 400;

		var label = new haxe.ui.components.Label();
		label.width = 400;
		if (Networker.login == null)
			label.text = '$enemy is hosting a challenge. First one to accept it will become an opponent\nYou will be playing as guest';
		else
			label.text = '$enemy is hosting a challenge. First one to accept it will become an opponent\nYou are joining the game as ${Networker.login}';
		mainMenu.addComponent(label);

		var joinButton = new haxe.ui.components.Button();
		joinButton.width = 200;
		joinButton.x = 100;
		joinButton.text = "Accept challenge";
		mainMenu.addComponent(joinButton);

		joinButton.onClick = (e) -> {
			Networker.acceptOpen(enemy);
		}

		joinMenu.x = (Browser.window.innerWidth - joinMenu.width) / 2;
		joinMenu.y = 100;
		addChild(joinMenu);
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
		Networker.registerGameEvents(onMove, onTimeCorrection, onEnded);
		removeChild(mainMenu);

		gameboard = new Field(data.colour);
		gameboard.x = (Browser.window.innerWidth - gameboard.width) / 2;
		gameboard.y = 100;

		sidebox = new Sidebox(data.startSecs, data.bonusSecs, Networker.login, data.enemy, data.colour == 'white');
		sidebox.x = gameboard.x + gameboard.width + 10;
		sidebox.y = gameboard.y + (gameboard.height - 380 - Math.sqrt(3) * Field.a) / 2;

		Browser.window.history.pushState({}, "Intellector", "?id=" + data.match_id);
		addChild(gameboard);
		addChild(sidebox);
		Assets.getSound("sounds/notify.mp3").play();	
	}

	private function onTimeCorrection(data:TimeData) 
	{
		sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
	}

	private function onMove(data:MoveData) 
	{
		var from = new IntPoint(data.fromI, data.fromJ);
		var to = new IntPoint(data.toI, data.toJ);
		var movingFigure = gameboard.getFigure(from);
		var ontoFigure = gameboard.getFigure(to);
		var opponentColor:FigureColor = gameboard.playerColor == White? Black : White;
		var morphedInto = data.morphInto == null? null : FigureType.createByName(data.morphInto);
		var capture = ontoFigure != null && ontoFigure.color == gameboard.playerColor;
		var mate = capture && ontoFigure.type == Intellector;

		sidebox.makeMove(opponentColor, movingFigure.type, to, capture, mate);
		gameboard.move(from, to, morphedInto);
	}

	private function onEnded(data:GameOverData) 
	{
		Networker.registerMainMenuEvents();

		if (data.reason != 'mate')
			sidebox.onNonMateEnded();

		var resultMessage;
		if (data.winner_color == "")
			resultMessage = "½ - ½.";
		else if (data.winner_color == gameboard.playerColor.getName().toLowerCase())
			if (data.reason == 'mate')
				resultMessage = "You won.";
			else if (data.reason == 'timeout')
				resultMessage = "You won by timeout.";
			else
				resultMessage = "Opponent disconnected. You won.";
		else if (data.reason == 'timeout')
			resultMessage = "You lost by timeout.";
		else
			resultMessage = "You lost.";

		Assets.getSound("sounds/notify.mp3").play();
		Dialogs.info("Game over. " + resultMessage, "Game ended");

		removeChild(sidebox);
		removeChild(gameboard);

		Browser.window.history.pushState({}, "Intellector", "");
		addChild(mainMenu);
	}
}

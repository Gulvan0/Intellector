package;

import haxe.ui.components.TextField;
import Networker.OpenChallengeData;
import Networker.MessageData;
import haxe.ui.containers.ScrollView;
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
using StringTools;

enum SignType
{
	SignIn;
	SignUp;
}

class Main extends Sprite
{

	private var changes:Label;
	private var signinMenu:VBox;
	private var mainMenu:VBox;
	private var hostingMenu:VBox;
	private var joinMenu:VBox;
	private var gameboard:Field;
	public static var sidebox:Sidebox;
	public static var chatbox:Chatbox;
	public static var infobox:GameInfoBox;

	private var errorLabel:Label;
	private var fadeTimer:Null<Timer>;

	public function new()
	{
		super();
		Toolkit.init();
		OpeningTree.init();
		Figure.initFigures();
		Networker.connect(drawGame, onConnected);
	}

	private function onConnected()
	{
		changes = new Label();
		changes.htmlText = Changes.getFormatted();
		changes.width = 300;
		changes.x = 15;
		changes.y = 10;
		changes.visible = false;
		addChild(changes);

		var searcher = new URLSearchParams(Browser.location.search);
		if (Cookie.exists("saved_login") && Cookie.exists("saved_password"))
			Networker.signin(Cookie.get("saved_login"), Cookie.get("saved_password"), onAutologinResults);
		else if (searcher.has("id"))
			Networker.getGame(Std.parseInt(searcher.get("id")), (s)->{drawSigninMenu();}, (s)->{drawSigninMenu();}, drawSigninMenu);
		else if (searcher.has("ch"))
			Networker.getOpenChallenge(searcher.get("ch"), (data)->{drawJoinGame(data);}, drawSigninMenu);
		else
			drawSigninMenu();
	}

	private function onAutologinResults(result:String)
	{
		if (result == 'success')
		{
			var searcher = new URLSearchParams(Browser.location.search);
			if (searcher.has("id"))
				Networker.getGame(Std.parseInt(searcher.get("id")), (s)->{drawMainMenu();}, (s)->{drawMainMenu();}, drawMainMenu);
			else if (searcher.has("ch") && searcher.get("ch") != Networker.login)
				Networker.getOpenChallenge(searcher.get("ch"), (data)->{drawJoinGame(data);}, drawMainMenu);
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

	private function onSignResults(type:SignType, result:String)
	{
		if (result == 'success')
		{
			removeChild(signinMenu);
			drawMainMenu();
		}
		else
		{
			if (type == SignIn)
				if (result == 'online')
					displayLoginError("An user with this login is already online");
				else
					displayLoginError("Invalid login/password");
			else
				displayLoginError("An user with this login already exists");
		}
	}

	private function drawSigninMenu() 
	{
		changes.visible = true;

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
			if (loginField.text == "" || passField.text == "" || loginField.text == null || passField.text == null)
				displayLoginError("You need to specify both the login and the password");
			else
				Networker.signin(loginField.text, passField.text, onSignResults.bind(SignIn));
		}

		var regbtn = new haxe.ui.components.Button();
		regbtn.text = "Register";
		regbtn.width = loginField.width / 2 - 5;
		btns.addComponent(regbtn);

		regbtn.onClick = (e) -> {
			if (loginField.text == "" || passField.text == "" || loginField.text == null || passField.text == null)
				displayLoginError("You need to specify both the login and the password");
			else
				Networker.register(loginField.text, passField.text, onSignResults.bind(SignUp));
		}
		
		signinMenu.addComponent(btns);

		errorLabel = new haxe.ui.components.Label();
		errorLabel.text = "Invalid login/password";
		errorLabel.alpha = 0;
		errorLabel.width = loginField.width;
		errorLabel.textAlign = "center";
		signinMenu.addComponent(errorLabel);

		signinMenu.x = (Browser.window.innerWidth - signinMenu.width) / 2;
		signinMenu.y = 100;
		addChild(signinMenu);
	}

	private function drawMainMenu() 
	{
		changes.visible = true;

		Browser.window.history.pushState({}, "Intellector", "/");
		Networker.registerMainMenuEvents();

		mainMenu = new VBox();
		mainMenu.width = 200;

		var calloutBtn = new haxe.ui.components.Button();
		calloutBtn.width = 200;
		calloutBtn.text = "Send challenge";
		mainMenu.addComponent(calloutBtn);

		calloutBtn.onClick = (e) -> {
			var response = Browser.window.prompt("Enter the callee's username");

			if (response == null)
				return;

			Dialogs.specifyChallengeParams(Networker.sendChallenge.bind(response), ()->{});
		}

		var openCalloutBtn = new haxe.ui.components.Button();
		openCalloutBtn.width = 200;
		openCalloutBtn.text = "Host open challenge";
		mainMenu.addComponent(openCalloutBtn);

		openCalloutBtn.onClick = (e) -> {
			Dialogs.specifyChallengeParams(drawOpenChallengeHosting, ()->{});
		}

		mainMenu.x = (Browser.window.innerWidth - mainMenu.width) / 2;
		mainMenu.y = 100;
		addChild(mainMenu);
	}

	private function drawOpenChallengeHosting(startSecs:Int, bonusSecs:Int) 
	{
		Networker.sendOpenChallenge(startSecs, bonusSecs);
		
		removeChild(mainMenu);
		removeChild(changes);

		hostingMenu = new VBox();
		hostingMenu.width = 800;

		var firstLabel:Label = new Label();
		firstLabel.htmlText = '<font size="16">Challenge by ${Networker.login}<br>${startSecs/60}+$bonusSecs<br>Share the link to invite your opponent:</font>';
		firstLabel.textAlign = 'center';
		firstLabel.width = 800;
		hostingMenu.addComponent(firstLabel);

		var linkText:TextField = new TextField();
		linkText.text = 'intellector.surge.sh/?ch=${Networker.login}';
		linkText.width = 800;
		hostingMenu.addComponent(linkText);

		var secondLabel:Label = new Label();
		secondLabel.htmlText = '<font size="16">First one to follow the link will join the game</font>';
		secondLabel.textAlign = 'center';
		secondLabel.width = 800;
		hostingMenu.addComponent(secondLabel);

		hostingMenu.x = (Browser.window.innerWidth - hostingMenu.width) / 2;
		hostingMenu.y = 100;
		addChild(hostingMenu);
	}

	private function drawJoinGame(data:OpenChallengeData) 
	{
		changes.visible = false;

		joinMenu = new VBox();
		joinMenu.width = 800;

		var label = new haxe.ui.components.Label();
		label.width = 800;
		label.htmlText = '<font size="16">${data.challenger} is hosting a challenge (${data.startSecs/60}+${data.bonusSecs}). First one to accept it will become an opponent\n';
		if (Networker.login == null)
			label.htmlText += 'You will be playing as guest';
		else
			label.htmlText += 'You are joining the game as ${Networker.login}';
		label.htmlText += '</font>';
		label.textAlign = 'center';
		joinMenu.addComponent(label);

		var joinButton = new haxe.ui.components.Button();
		joinButton.width = 200;
		joinButton.horizontalAlign = 'center';
		joinButton.text = "Accept challenge";
		joinMenu.addComponent(joinButton);

		joinButton.onClick = (e) -> {
			Networker.acceptOpen(data.challenger);
		}

		joinMenu.x = (Browser.window.innerWidth - joinMenu.width) / 2;
		joinMenu.y = 100;
		addChild(joinMenu);
	}

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

	private function drawGame(data:BattleData) 
	{
		changes.visible = false;

		Networker.registerGameEvents(onMove, onMessage, onTimeCorrection, onEnded);
		removeChild(mainMenu);
		removeChild(joinMenu);
		removeChild(hostingMenu);

		gameboard = new Field(data.colour);
		gameboard.x = (Browser.window.innerWidth - gameboard.width) / 2;
		gameboard.y = 100;

		sidebox = new Sidebox(data.startSecs, data.bonusSecs, Networker.login, data.enemy, data.colour == 'white');
		sidebox.x = gameboard.x + gameboard.width + 10;
		sidebox.y = gameboard.y + (gameboard.height - 380 - Math.sqrt(3) * Field.a) / 2;

		chatbox = new Chatbox(gameboard.height * 0.75);
		chatbox.x = gameboard.x - Chatbox.WIDTH - Field.a - 30;
		chatbox.y = gameboard.y + gameboard.height * 0.25 - Field.a * Math.sqrt(3) / 2;
		addChild(chatbox);

		var whiteLogin = data.colour == 'white'? Networker.login : data.enemy;
		var blackLogin = data.colour == 'black'? Networker.login : data.enemy;
		infobox = new GameInfoBox(Chatbox.WIDTH, gameboard.height * 0.23, data.startSecs, data.bonusSecs, whiteLogin, blackLogin, data.colour == 'white');
		infobox.x = gameboard.x - Chatbox.WIDTH - Field.a - 30;
		infobox.y = gameboard.y - Field.a * Math.sqrt(3) / 2;
		addChild(infobox);

		Browser.window.history.pushState({}, "Intellector", "?id=" + data.match_id);
		addChild(gameboard);
		addChild(sidebox);
		Assets.getSound("sounds/notify.mp3").play();	
	}

	private function onTimeCorrection(data:TimeData) 
	{
		sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
	}

	private function onMessage(data:MessageData) 
	{
		chatbox.appendMessage(data.issuer_login, data.message);
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
		var castle = ontoFigure != null && ontoFigure.color == opponentColor && (ontoFigure.type == Intellector && movingFigure.type == Defensor || ontoFigure.type == Defensor && movingFigure.type == Intellector);

		sidebox.makeMove(opponentColor, movingFigure.type, to, capture, mate, castle, morphedInto);
		infobox.makeMove(data.fromI, data.fromJ, data.toI, data.toJ, morphedInto);
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
		removeChild(chatbox);
		removeChild(infobox);
		removeChild(gameboard);

		Browser.window.history.pushState({}, "Intellector", "/");
		if (Networker.login.startsWith("guest_"))
			Networker.dropConnection();
		else 
			addChild(mainMenu);
	}
}

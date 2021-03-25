package;

import Networker.OngoingBattleData;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
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
	private var game:GameCompound;

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

	private function onSignResults(type:SignType, login:String, password:String, remember:Bool, result:String)
	{
		if (result == 'success')
		{
			if (remember)
			{
				Cookie.set("saved_login", login, 60 * 60 * 24 * 365 * 5, "/");
				Cookie.set("saved_password", password, 60 * 60 * 24 * 365 * 5, "/");
			}
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
		Browser.window.history.pushState({}, "Intellector", "/");
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

		var rememberMe = new CheckBox();
		rememberMe.selected = false;
		rememberMe.text = "Remember me";
		rememberMe.horizontalAlign = 'center';
		signinMenu.addComponent(rememberMe);

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
				Networker.signin(loginField.text, passField.text, onSignResults.bind(SignIn, loginField.text, passField.text, rememberMe.selected));
		}

		var regbtn = new haxe.ui.components.Button();
		regbtn.text = "Register";
		regbtn.width = loginField.width / 2 - 5;
		btns.addComponent(regbtn);

		regbtn.onClick = (e) -> {
			if (loginField.text == "" || passField.text == "" || loginField.text == null || passField.text == null)
				displayLoginError("You need to specify both the login and the password");
			else
				Networker.register(loginField.text, passField.text, onSignResults.bind(SignUp, loginField.text, passField.text, rememberMe.selected));
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
		Browser.window.history.pushState({}, "Intellector", "/");
		changes.visible = true;

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
				Dialogs.specifyChallengeParams(Networker.sendChallenge.bind(response), ()->{});
		}

		var openCalloutBtn = new haxe.ui.components.Button();
		openCalloutBtn.width = 200;
		openCalloutBtn.text = "Host open challenge";
		mainMenu.addComponent(openCalloutBtn);

		openCalloutBtn.onClick = (e) -> {
			Dialogs.specifyChallengeParams(drawOpenChallengeHosting, ()->{});
		}

		var analysisBtn = new haxe.ui.components.Button();
		analysisBtn.text = "Analysis board";
		analysisBtn.width = calloutBtn.width;
		analysisBtn.horizontalAlign = 'center';
		mainMenu.addComponent(analysisBtn);

		analysisBtn.onClick = (e) -> {
			drawAnalysisBoard();
		}

		var spectateBtn = new haxe.ui.components.Button();
		spectateBtn.text = "Spectate";
		spectateBtn.width = calloutBtn.width;
		spectateBtn.horizontalAlign = 'center';
		mainMenu.addComponent(spectateBtn);

		spectateBtn.onClick = (e) -> {
			var response = Browser.window.prompt("Enter the username of a player whose game you want to spectate");

			if (response != null)
				Networker.spectate(response, drawSpectation, (d)->{game.onMove(d);}, (d)->{game.onTimeCorrection(d);});
		}

		var logoutBtn = new haxe.ui.components.Button();
		logoutBtn.text = "Log Out";
		logoutBtn.width = calloutBtn.width / 2;
		logoutBtn.horizontalAlign = 'center';
		mainMenu.addComponent(logoutBtn);

		logoutBtn.onClick = (e) -> {
			Cookie.remove("saved_login");
			Cookie.remove("saved_password");
			renewSession();
		}

		mainMenu.x = (Browser.window.innerWidth - mainMenu.width) / 2;
		mainMenu.y = 100;
		addChild(mainMenu);
	}

	private function renewSession() 
	{
		removeChildren();
		Networker.dropConnection();
		Networker.connect(drawGame, onConnected);
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
		removeChildren();

		game = GameCompound.buildActive(data);
		addChild(game);

		Networker.registerGameEvents(game.onMove, game.onMessage, game.onTimeCorrection, onEnded, game.onSpectatorConnected, game.onSpectatorDisonnected);

		Browser.window.history.pushState({}, "Intellector", "?id=" + data.match_id);
		Assets.getSound("sounds/notify.mp3").play();	
	}

	private function drawAnalysisBoard() 
	{
		removeChildren();
		game = GameCompound.buildAnalysis(onReturn);
		addChild(game);
	}

	private function drawSpectation(data:OngoingBattleData) 
	{
		removeChildren();
		game = GameCompound.buildSpectators(data, () -> {
			Networker.stopSpectate(); 
			onReturn();
		});
		addChild(game);
	}

	private function onReturn()
	{
		removeChild(game);
		game = null;
		drawMainMenu();
	}

	private function onEnded(data:GameOverData) 
	{
		Networker.registerMainMenuEvents();

		game.terminate();

		var resultMessage;
		if (data.winner_color == "")
			resultMessage = "½ - ½";
		else if (data.winner_color == game.playerColor.getName().toLowerCase())
			resultMessage = "You won";
		else 
			resultMessage = "You lost";

		var explanation = switch data.reason
		{
			case 'mate': ".";
			case 'breakthrough': " by breakthrough.";
			case 'timeout': " by timeout.";
			case 'resignation': " by resignation.";
			case 'abandon': ". Opponent disconnected.";
			case 'threefoldrepetition': " (Threefold repetition).";
			case 'hundredmoverule': " (Hundred move rule).";
			case 'drawagreement': " (by agreement).";
			default: "";
		};

		Assets.getSound("sounds/notify.mp3").play();
		Dialogs.info("Game over. " + resultMessage + explanation, "Game ended");

		removeChild(game);
		game = null;

		Browser.window.history.pushState({}, "Intellector", "/");
		if (Networker.login.startsWith("guest_"))
			renewSession();
		else 
			addChild(mainMenu);
	}
}

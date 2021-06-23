package;

import openings.OpeningTree;
import dict.Dictionary;
import haxe.ui.events.UIEvent;
import haxe.ui.components.OptionBox;
import Networker.OngoingBattleData;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.TextField;
import Networker.OpenChallengeData;
import Networker.MessageData;
import haxe.ui.containers.ScrollView;
import struct.PieceColor;
import Networker.TimeData;
import js.html.URLSearchParams;
import js.Cookie;
import struct.PieceType;
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
		Browser.document.addEventListener('contextmenu', event -> event.preventDefault());
		Toolkit.init();
		OpeningTree.init();
		AssetManager.init();
		initConstants();
		Changes.initChangelog();
		Networker.connect(drawGame, onConnected, removeChildren);
	}

    private function initConstants() 
    {
        if (Cookie.exists("markup"))
            Field.markup = Markup.createByName(Cookie.get("markup"));
        if (Cookie.exists("lang"))
            Dictionary.lang = Language.createByName(Cookie.get("lang"));
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
			Networker.getGame(Std.parseInt(searcher.get("id")), (d)->{drawSigninMenu();}, (s)->{drawSigninMenu();}, drawSigninMenu);
		else if (searcher.has("ch"))
			Networker.getOpenChallenge(searcher.get("ch"), (data)->{drawJoinGame(data);}, (d)->{drawSigninMenu();}, drawSigninMenu);
		else
			drawSigninMenu();
	}

	private function onAutologinResults(result:String)
	{
		function onGameInProcess(data:OngoingBattleData)
		{
			if (data.whiteLogin.toLowerCase() == Networker.login.toLowerCase())
			{
				data.whiteLogin = Networker.login;
				drawGameOnReconnect(data);
			}
			else if (data.blackLogin.toLowerCase() == Networker.login.toLowerCase())
			{
				data.blackLogin = Networker.login;
				drawGameOnReconnect(data);
			}
			else
				drawSpectation(data);
		}

		if (result == 'success')
		{
			var searcher = new URLSearchParams(Browser.location.search);
			if (searcher.has("id"))
				Networker.getGame(Std.parseInt(searcher.get("id")), onGameInProcess, (s)->{drawMainMenu();}, drawMainMenu);
			else if (searcher.has("ch") && searcher.get("ch") != Networker.login)
				Networker.getOpenChallenge(searcher.get("ch"), (data)->{drawJoinGame(data);}, onGameInProcess, drawMainMenu);
			else
				drawMainMenu();
		}
		else
		{
			if (result != 'online')
			{
				Cookie.remove("saved_login");
				Cookie.remove("saved_password");
			}
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
					displayLoginError(Dictionary.getPhrase(ALREADY_LOGGED));
				else
					displayLoginError(Dictionary.getPhrase(INVALID_PASSWORD));
			else
				displayLoginError(Dictionary.getPhrase(ALREADY_REGISTERED));
		}
	}

	private function drawSigninMenu() 
	{
		URLEditor.clear();
		changes.visible = true;

		signinMenu = new VBox();
		signinMenu.width = 200;

		var loginField = new haxe.ui.components.TextField();
		loginField.placeholder = Dictionary.getPhrase(LOGIN_FIELD_TITLE);
		loginField.width = 200;
		loginField.restrictChars = "A-Za-z0-9";
		signinMenu.addComponent(loginField);

		var passField = new haxe.ui.components.TextField();
		passField.placeholder = Dictionary.getPhrase(PASSWORD_FIELD_TITLE);
		passField.width = loginField.width;
		passField.restrictChars = "A-Za-z0-9";
		passField.password = true;
		signinMenu.addComponent(passField);

		var rememberMe = new CheckBox();
		rememberMe.selected = false;
		rememberMe.text = Dictionary.getPhrase(REMEMBER_ME_CHECKBOX_TITLE);
		rememberMe.horizontalAlign = 'center';
		signinMenu.addComponent(rememberMe);

		var btns:HBox = new HBox();
		btns.horizontalAlign = "center";

		var signinbtn = new haxe.ui.components.Button();
		signinbtn.text = Dictionary.getPhrase(SIGN_IN_BTN);
		signinbtn.width = loginField.width / 2 - 5;
		btns.addComponent(signinbtn);

		signinbtn.onClick = (e) -> {
			if (loginField.text == "" || passField.text == "" || loginField.text == null || passField.text == null)
				displayLoginError(Dictionary.getPhrase(SPECIFY_BOTH_REG_ERROR));
			else
				Networker.signin(loginField.text, passField.text, onSignResults.bind(SignIn, loginField.text, passField.text, rememberMe.selected));
		}

		var regbtn = new haxe.ui.components.Button();
		regbtn.text = Dictionary.getPhrase(REGISTER_BTN);
		regbtn.width = loginField.width / 2 - 5;
		btns.addComponent(regbtn);

		regbtn.onClick = (e) -> {
			if (loginField.text == "" || passField.text == "" || loginField.text == null || passField.text == null)
				displayLoginError(Dictionary.getPhrase(SPECIFY_BOTH_REG_ERROR));
			else
				Networker.register(loginField.text, passField.text, onSignResults.bind(SignUp, loginField.text, passField.text, rememberMe.selected));
		}
		
		signinMenu.addComponent(btns);

		errorLabel = new haxe.ui.components.Label();
		errorLabel.text = Dictionary.getPhrase(INVALID_PASSWORD);
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
		URLEditor.clear();
		changes.visible = true;

		Networker.registerMainMenuEvents();

		mainMenu = new VBox();
		mainMenu.width = 200;

		var calloutBtn = new haxe.ui.components.Button();
		calloutBtn.width = 200;
		calloutBtn.text = Dictionary.getPhrase(SEND_CHALLENGE);
		mainMenu.addComponent(calloutBtn);

		calloutBtn.onClick = (e) -> {
			var response = Browser.window.prompt(Dictionary.getPhrase(ENTER_CALLEE));

			if (response != null)
				Dialogs.specifyChallengeParams(Networker.sendChallenge.bind(response), ()->{});
		}

		var openCalloutBtn = new haxe.ui.components.Button();
		openCalloutBtn.width = 200;
		openCalloutBtn.text = Dictionary.getPhrase(OPEN_CHALLENGE_BTN);
		mainMenu.addComponent(openCalloutBtn);

		openCalloutBtn.onClick = (e) -> {
			Dialogs.specifyChallengeParams(drawOpenChallengeHosting, ()->{});
		}

		var analysisBtn = new haxe.ui.components.Button();
		analysisBtn.text = Dictionary.getPhrase(ANALYSIS_BTN);
		analysisBtn.width = calloutBtn.width;
		analysisBtn.horizontalAlign = 'center';
		mainMenu.addComponent(analysisBtn);

		analysisBtn.onClick = (e) -> {
			drawAnalysisBoard();
		}

		var spectateBtn = new haxe.ui.components.Button();
		spectateBtn.text = Dictionary.getPhrase(SPECTATE_BTN);
		spectateBtn.width = calloutBtn.width;
		spectateBtn.horizontalAlign = 'center';
		mainMenu.addComponent(spectateBtn);

		spectateBtn.onClick = (e) -> {
			var response = Browser.window.prompt(Dictionary.getPhrase(ENTER_SPECTATED));

			if (response != null)
				sendSpectateRequest(response);
		}

		var settingsBtn = new haxe.ui.components.Button();
		settingsBtn.text = Dictionary.getPhrase(SETTINGS_BTN);
		settingsBtn.width = calloutBtn.width;
		settingsBtn.horizontalAlign = 'center';
		mainMenu.addComponent(settingsBtn);

		settingsBtn.onClick = (e) -> {
			drawSettings();
		}

		var logoutBtn = new haxe.ui.components.Button();
		logoutBtn.text = Dictionary.getPhrase(LOG_OUT_BTN);
		logoutBtn.width = calloutBtn.width / 2;
		logoutBtn.horizontalAlign = 'center';
		mainMenu.addComponent(logoutBtn);

		logoutBtn.onClick = (e) -> {
			Cookie.remove("saved_login");
			Cookie.remove("saved_password");
			Networker.dropConnection();
		}

		mainMenu.x = (Browser.window.innerWidth - mainMenu.width) / 2;
		mainMenu.y = 100;
		addChild(mainMenu);
	}

	private function drawSettings() 
	{
		removeChildren();

		var box:VBox = new VBox();

		var header:Label = new Label();
		header.text = Dictionary.getPhrase(SETTINGS_TITLE);
		header.customStyle = {fontSize: 16};
		header.horizontalAlign = "center";
		box.addComponent(header);

		var markup:HBox = new HBox();

		var markupLabel:Label = new Label();
		markupLabel.text = Dictionary.getPhrase(SETTINGS_MARKUP_TITLE);
		markup.addComponent(markupLabel);

		var markupNone:OptionBox = new OptionBox();
		markupNone.text = Dictionary.getPhrase(SETTINGS_MARKUP_TYPE_NONE);
		markupNone.componentGroup = "settings-markup";
		markup.addComponent(markupNone);

		var markupSide:OptionBox = new OptionBox();
		markupSide.text = Dictionary.getPhrase(SETTINGS_MARKUP_TYPE_SIDE);
		markupSide.componentGroup = "settings-markup";
		markup.addComponent(markupSide);

		var markupOver:OptionBox = new OptionBox();
		markupOver.text = Dictionary.getPhrase(SETTINGS_MARKUP_TYPE_OVER);
		markupOver.componentGroup = "settings-markup";
		markup.addComponent(markupOver);

		switch Field.markup 
		{
			case None: markupNone.selected = true;
			case Side: markupSide.selected = true;
			case Over: markupOver.selected = true;
		}
		
		markupNone.onChange = (e) -> {
			if (markupNone.selected)
			{
				Field.markup = None;
				Cookie.set("markup", "None", 60 * 60 * 24 * 365 * 5);
			}
		};
		markupSide.onChange = (e) -> {
			if (markupSide.selected)
			{
				Field.markup = Side;
				Cookie.set("markup", "Side", 60 * 60 * 24 * 365 * 5);
			}
		};
		markupOver.onChange = (e) -> {
			if (markupOver.selected)
			{
				Field.markup = Over;
				Cookie.set("markup", "Over", 60 * 60 * 24 * 365 * 5);
			}
		};

		box.addComponent(markup);


		var lang:HBox = new HBox();

		var langLabel:Label = new Label();
		langLabel.text = Dictionary.getPhrase(SETTINGS_LANGUAGE_TITLE);
		lang.addComponent(langLabel);

		var langEN:OptionBox = new OptionBox();
		langEN.text = "English";
		langEN.componentGroup = "settings-lang";
		lang.addComponent(langEN);

		var langRU:OptionBox = new OptionBox();
		langRU.text = "Русский";
		langRU.componentGroup = "settings-lang";
		lang.addComponent(langRU);

		switch Dictionary.lang
		{
			case EN: langEN.selected = true;
			case RU: langRU.selected = true;
		}
		
		langEN.onChange = (e) -> {
			if (langEN.selected)
			{
				Dictionary.lang = EN;
				Cookie.set("lang", "EN", 60 * 60 * 24 * 365 * 5);
			}
		};
		langRU.onChange = (e) -> {
			if (langRU.selected)
			{
				Dictionary.lang = RU;
				Cookie.set("lang", "RU", 60 * 60 * 24 * 365 * 5);
			}
		};

		box.addComponent(lang);


		box.x = (Browser.window.innerWidth - 290) / 2;
		box.y = 100;
		addChild(box);

		var returnBtn = new Button();
		returnBtn.width = 100;
		returnBtn.text = Dictionary.getPhrase(RETURN);
		returnBtn.onClick = (e) -> {
			removeChild(returnBtn);
			removeChild(box);
			drawMainMenu();
		};
            
        returnBtn.x = 10;
	    returnBtn.y = 10;
	    addChild(returnBtn);
	}

	private function sendSpectateRequest(player:String) 
	{
		Networker.spectate(player, drawSpectation, (d)->{game.onMove(d);}, (d)->{game.onTimeCorrection(d);});
	}

	private function drawOpenChallengeHosting(startSecs:Int, bonusSecs:Int) 
	{
		Networker.sendOpenChallenge(startSecs, bonusSecs);
		
		removeChild(mainMenu);
		removeChild(changes);

		hostingMenu = new VBox();
		hostingMenu.width = 800;

		var firstLabel:Label = new Label();
		firstLabel.customStyle = {fontSize: 16};
		firstLabel.text = Dictionary.challengeByText(Networker.login, startSecs, bonusSecs);
		firstLabel.textAlign = 'center';
		firstLabel.width = 800;
		hostingMenu.addComponent(firstLabel);

		var linkText:TextField = new TextField();
		linkText.text = URLEditor.getChallengeLink(Networker.login);
		linkText.width = 800;
		hostingMenu.addComponent(linkText);

		var secondLabel:Label = new Label();
		secondLabel.text = Dictionary.getPhrase(OPEN_CHALLENGE_FIRST_TO_FOLLOW_NOTE);
		secondLabel.customStyle = {fontSize: 16};
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
		label.text = Dictionary.isHostingAChallengeText(data);
		if (Networker.login == null)
			label.text += Dictionary.getPhrase(WILL_BE_GUEST);
		else
			label.text += Dictionary.getPhrase(JOINING_AS) + Networker.login;
		label.customStyle = {fontSize: 16};
		label.textAlign = 'center';
		joinMenu.addComponent(label);

		var joinButton = new haxe.ui.components.Button();
		joinButton.width = 200;
		joinButton.horizontalAlign = 'center';
		joinButton.text = Dictionary.getPhrase(ACCEPT_CHALLENGE);
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

		URLEditor.assignID(data.match_id);
		Assets.getSound("sounds/notify.mp3").play();	
	}

	private function drawGameOnReconnect(data:OngoingBattleData) 
	{
		removeChildren();

		game = GameCompound.buildActiveReconnect(data);
		addChild(game);

		Networker.registerGameEvents(game.onMove, game.onMessage, game.onTimeCorrection, onEnded, game.onSpectatorConnected, game.onSpectatorDisonnected);

		URLEditor.assignID(data.match_id);
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
			resultMessage = Dictionary.getPhrase(WIN_MESSAGE_PREAMBLE);
		else 
			resultMessage = Dictionary.getPhrase(LOSS_MESSAGE_PREAMBLE);

		var explanation = switch data.reason
		{
			case 'mate': ".";
			case 'breakthrough': Dictionary.getPhrase(GAME_OVER_REASON_BREAKTHROUGH);
			case 'timeout': Dictionary.getPhrase(GAME_OVER_REASON_TIMEOUT);
			case 'resignation': Dictionary.getPhrase(GAME_OVER_REASON_RESIGN);
			case 'abandon': Dictionary.getPhrase(GAME_OVER_REASON_DISCONNECT);
			case 'threefoldrepetition': Dictionary.getPhrase(GAME_OVER_REASON_THREEFOLD);
			case 'hundredmoverule': Dictionary.getPhrase(GAME_OVER_REASON_HUNDRED);
			case 'drawagreement': Dictionary.getPhrase(GAME_OVER_REASON_AGREEMENT);
			default: "";
		};

		Assets.getSound("sounds/notify.mp3").play();
		Dialogs.info(Dictionary.getPhrase(GAME_OVER) + resultMessage + explanation, Dictionary.getPhrase(GAME_ENDED));

		removeChild(game);
		game = null;

		URLEditor.clear();
		if (Networker.login.startsWith("guest_"))
			Networker.dropConnection();
		else 
			addChild(mainMenu);
	}
}

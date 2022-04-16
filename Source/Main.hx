package;

import net.ServerEvent;
import js.html.URLSearchParams;
import browser.CredentialCookies;
import gfx.ScreenManager;
import gfx.screens.Analysis;
import gfx.screens.LanguageSelectIntro;
import haxe.ui.Toolkit;
import js.Browser;
import net.LoginManager;
import openfl.display.Sprite;
import openings.OpeningTree;
import tests.UITest;
import tests.ui.game.TChatBox;
import utils.AssetManager;

using StringTools;

class Main extends Sprite
{
	private var languageSelectScreen:Sprite;

	public function new()
	{
		super();
		init();
		//start();
		addChild(new UITest(new TChatBox()));
	}

	private function init() 
	{
		Browser.document.addEventListener('contextmenu', event -> event.preventDefault());
		var element = Browser.document.getElementById("openfl-content");
		element.style.width = '${Browser.window.innerWidth}px';
		element.style.height = '${Browser.window.innerHeight}px';

		Toolkit.init();
		OpeningTree.init();
		AssetManager.init();
		Changes.initChangelog();

		ScreenManager.launch(this);
	}

	private function start() 
	{
		var langInitializedFromCookie:Bool = Preferences.language.load();

		if (langInitializedFromCookie)
			onLanguageReady();
		else
		{
			languageSelectScreen = new LanguageSelectIntro();
			//TODO: Fill
			addChild(languageSelectScreen);
		}
	}

	private function onLanguageReady() 
	{
		if (languageSelectScreen != null)
		{
			removeChild(languageSelectScreen);
			languageSelectScreen = null;
		}

		Networker.onConnectionEstabilished = onConnected;
		Networker.onConnectionFailed = onConnectionFailed;
		Networker.launch();
	}

	private function onConnectionFailed(e)
	{
		var analysisScreen:Analysis = ScreenManager.toOfflineAnalysis();
		Networker.startReconnectAttempts(() -> {
			analysisScreen.enableMenu();
			if (CredentialCookies.hasLoginDetails())
				LoginManager.signin(CredentialCookies.getLogin(), CredentialCookies.getPassword(), true);
		});
	}

	private function onConnected()
	{
		var searcher = new URLSearchParams(Browser.location.search);
        if (searcher.has("p"))
        {
			var pagePathParts:Array<String> = searcher.get("p").split('/');
			var section:String = pagePathParts[0];

			if (section == "login")
				ScreenManager.toScreen(LoginRegister); //* Bypass the usual procedure (no need to login)
			else
				navigate(section, pagePathParts.slice(1));
		}
		else if (searcher.has("id")) //* These are added for the backward compatibility
			navigate("live", [searcher.get("id")]);
        else if (searcher.has("ch"))
            navigate("join", [searcher.get("ch")]);
        else
            navigate("home", []);
	}

    private function navigate(section:String, pathPartsAfter:Array<String>)
    {
		if (CredentialCookies.hasLoginDetails())
			LoginManager.signin(CredentialCookies.getLogin(), CredentialCookies.getPassword(), true);

        switch section
        {
            case "analysis":  
                ScreenManager.toScreen(Analysis(null, null));
            case "join":
				//TODO: Process "owner playing" situation in GeneralObserver
				Networker.emitEvent(GetOpenChallenge(pathPartsAfter[0]));
            case "player":
				//TODO: Player exists? (via GetProfile: can return either PlayerNotFound or PlayerProfileDetails[last seen, roles, ..., first 10 games, first 10 studies])
                ScreenManager.toScreen(PlayerProfile(pathPartsAfter[0]));
            case "study":
				//TODO: Get study, delay toScreen(), process StudyNotFound in GeneralObserver - or should I consider another responsible for this?
                ScreenManager.toScreen(Analysis(null, Std.parseInt(pathPartsAfter[0])));
            case "live": 
                var gameID:Null<Int> = Std.parseInt(pathPartsAfter[0]);
                if (gameID != null)
                	{} //TODO: GetGame, process possible answers, if ongoing: isLogged + isAmongPlayers
                else
                    ScreenManager.toScreen(MainMenu);
            default:
                ScreenManager.toScreen(MainMenu);
        }
	}
}

package;

import serialization.GameLogParser;
import utils.Changelog;
import gfx.screens.OpenChallengeJoining;
import gfx.components.Dialogs;
import tests.ui.analysis.TAnalysisScreen;
import haxe.ui.locale.LocaleManager;
import struct.PieceColor;
import utils.TimeControl;
import net.Requests;
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
import utils.AssetManager;

using StringTools;

/**
	This class contains the entry point of a program followed
	by all the necessary initialization.

	The file is structured in a waterfall manner: as you go
	through all of the initialization steps, you descend lower
	and lower.

	Generally, initialization consists of the following phases:
	- Some purely technical aspects for the app to work
	correctly: init();
	- An attempt to load user's language preference from their
	cookies; if no exist (usually when this is their first visit),
	the user is asked to choose: start();
	- Connection attempt. If it is impossible to connect to the
	server, leave user in the "playground" (analysis board, that
	is), while actively trying to reconnect behind the scenes:
	onLanguageReady();
	- Auto Sign-In. Loads the user's credentials from the cookies
	to automatically log them in. Continues right after ANY 
	response from the server is received, since signing in isn't
	mandatory. For the same reason, jumps to the next step if no 
	credential cookies are found. Located in onConnected();
	- Path parsing. Retrieving the page the user requested from
	the URL search params: navigate() and navigateToSection(). 
	The former provides backward compatibility for the old URLs
	(pre-2.0). The latter one parses the
	modern paths;
	- Navigating to a respective page: all of the following 
	methods. The ones needing an additional data make use of a
	Requests class, retrieving the missing data from the server.
**/
class Main extends Sprite
{
	public function new()
	{
		super();
		init(start);
	}

	private function init(callback:Void->Void) 
	{
		Browser.window.onpopstate = navigate;
		Browser.document.addEventListener('contextmenu', event -> event.preventDefault());
		Browser.document.addEventListener('wheel', event -> {
			if (event.ctrlKey)
				event.preventDefault();
		}, true);
		OpeningTree.init();
		Changelog.init();
		
		Toolkit.init({container: stage});
		AssetManager.load(() -> {
			ScreenManager.launch();
			callback();
		});
	}

	private function start() 
	{
		var langInitializedFromCookie:Bool = Preferences.language.load();

		if (langInitializedFromCookie)
			onLanguageReady();
		else
			ScreenManager.toScreen(LanguageSelectIntro(onLanguageReady));
	}

	private function onLanguageReady() 
	{
		if (Preferences.language.get() == RU)
			LocaleManager.instance.language = "ru";
		else
			LocaleManager.instance.language = "en";

		Networker.onConnectionEstabilished = onConnected;
		Networker.onConnectionFailed = onConnectionFailed;
		//Networker.launch();
		//ScreenManager.toScreen(ChallengeJoining("Gulvan", new TimeControl(30, 0), Black));
		Networker.ignoreEmitCalls = true;
		LoginManager.login = "gulvan";
		ScreenManager.toScreen(LiveGame(1337, Past(GameLogParser.parse("#P|gulvan:kazvixx;
		#D|1659990040;
		#T|600/0;
		#S|bfrmrnrprqrriseteuivowgxnygzo!@oAgBnCgDoEiFeGeHiIrJrKrLrMr;
		2043;
		4443;
		4142;
		4342;
		3031;
		4241;
		3132;
		4130;
		3233;
		3020Liberator;
		3334;
		4635;
		6162;
		2634;
		#L|2134/11000;
		#R|b/res"), "kazvixx")));
	}

	private function onConnectionFailed(e)
	{
		ScreenManager.disableMenu();
		toAnalysis();
		Networker.startReconnectAttempts(() -> {
			ScreenManager.enableMenu();
			if (CredentialCookies.hasLoginDetails())
				LoginManager.signin(CredentialCookies.getLogin(), CredentialCookies.getPassword(), null, ()->{}, ()->{});
		});
	}

	private function onConnected()
	{
		ScreenManager.observeNetEvents();
		if (CredentialCookies.hasLoginDetails())
			LoginManager.signin(CredentialCookies.getLogin(), CredentialCookies.getPassword(), null, navigate, navigate);
		else
			navigate();
	}

	private function navigate()
	{
		var searcher = new URLSearchParams(Browser.location.search);
        if (searcher.has("p"))
        {
			var pagePathParts:Array<String> = searcher.get("p").split('/');
			var section:String = pagePathParts[0];

			navigateToSection(section, pagePathParts.slice(1));
		}
		else if (searcher.has("id")) //* These are added for the backward compatibility
			navigateToSection("live", [searcher.get("id")]);
        else if (searcher.has("ch"))
            navigateToSection("join", [searcher.get("ch")]);
        else
            navigateToSection("home", []);
	}

    private function navigateToSection(section:String, pathPartsAfter:Array<String>)
    {
		switch section
        {
            case "analysis":  
                toAnalysis();
            case "join":
				toOpenChallengeJoining(pathPartsAfter[0]);
            case "player":
				toProfile(pathPartsAfter[0]);
            case "study":
				toStudy(pathPartsAfter[0]);
            case "live": 
                toGame(pathPartsAfter[0]);
            default:
                ScreenManager.toScreen(MainMenu);
        }
	}

	private function toAnalysis() 
	{
		ScreenManager.toScreen(Analysis(null, null, null, null));
	}

	private function toOpenChallengeJoining(owner:String) 
	{
		Requests.getOpenChallenge(owner);
	}

	private function toProfile(login:String) 
	{
		Requests.getPlayerProfile(login);
	}

	private function toStudy(idStr:String) 
	{
		var id:Null<Int> = Std.parseInt(idStr);
		if (id != null)
			Requests.getStudy(id);
		else
			ScreenManager.toScreen(MainMenu);
	}

	private function toGame(idStr:String) 
	{
		var id:Null<Int> = Std.parseInt(idStr);
		if (id != null)
			Requests.getGame(id);
		else
			ScreenManager.toScreen(MainMenu);
	}
}

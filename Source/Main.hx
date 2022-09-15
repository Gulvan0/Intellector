package;

import gfx.basic_components.AutosizingLabel;
import struct.Situation;
import struct.ChallengeParams;
import serialization.GameLogParser;
import utils.Changelog;
import gfx.screens.OpenChallengeJoining;
import gfx.Dialogs;
import tests.ui.analysis.TAnalysisScreen;
import haxe.ui.locale.LocaleManager;
import struct.PieceColor;
import utils.TimeControl;
import net.Requests;
import js.html.URLSearchParams;
import browser.CredentialCookies;
import gfx.SceneManager;
import gfx.screens.Analysis;
import gfx.screens.LanguageSelectIntro;
import haxe.ui.Toolkit;
import js.Browser;
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
		Toolkit.scale = 1;
		AssetManager.load(callback);
	}

	private function start() 
	{
		var v = new AutosizingLabel();
		v.customStyle = {backgroundColor: 0xff0000, backgroundOpacity: 0.5};
		v.percentWidth = 100;
		v.text = "Lorem ipsum dolor sit amet";
		v.horizontalAlign = 'center';
		v.verticalAlign = 'center';
		haxe.ui.core.Screen.instance.addComponent(v);
		return;
		var langInitializedFromCookie:Bool = Preferences.language.load();

		SceneManager.launch();

		if (langInitializedFromCookie)
			onLanguageReady();
		else
			SceneManager.toScreen(LanguageSelectIntro(onLanguageReady));
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
		Networker.ignoreEmitCalls = true;
		LoginManager.imitateLoggedState("gulvan");
		/*SceneManager.toScreen(LiveGame(1337, Ongoing(GameLogParser.parse("#P|gulvan:kazvixx;
		#D|1659990040;
		#T|600/0;
		#S|bfrmrnrprqrriseteuivowgxnygzo!@oAgBnCgDoEiFeGeHiIrJrKrLrMr;
		2043/600000;
		4443/600000;
		4142/580000;
		4342/570000;
		3031/550000;
		4241/540000;
		3132/500000;
		4130/510000;
		3233/450000;
		3020Liberator/480000;
		3334/400000;
		4635/450000;
		6162/350000;
		2634/420000;"), 420, 325, Date.now().getTime(), "kazvixx")));*/
		//SceneManager.toScreen(ChallengeJoining(123, ChallengeParams.playFromPosParams(Situation.randomPlay(3))));
	}

	private function onConnectionFailed(e)
	{
		SceneManager.onConnectionError();
	}

	private function onConnected()
	{
		SceneManager.observeNetEvents();
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
                SceneManager.toScreen(MainMenu);
        }
	}

	private function toAnalysis() 
	{
		SceneManager.toScreen(Analysis(null, null, null, null));
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
			SceneManager.toScreen(MainMenu);
	}

	private function toGame(idStr:String) 
	{
		var id:Null<Int> = Std.parseInt(idStr);
		if (id != null)
			Requests.getGame(id);
		else
			SceneManager.toScreen(MainMenu);
	}
}

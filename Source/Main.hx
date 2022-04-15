package;

import gfx.ScreenManager;
import gfx.screens.LanguageSelectIntro;
import tests.ui.game.TChatBox;
import tests.ui.game.TSidebox;
import tests.ui.board.TGameBoard;
import tests.ui.board.TSelectableBoard;
import tests.ui.board.TBoard;
import gfx.game.Sidebox;
import net.LoginManager;
import gameboard.Board;
import haxe.ui.containers.Box;
import gfx.components.SpriteWrapper;
import utils.AssetManager;
import struct.Ply;
import struct.Variant;
import haxe.ui.components.Link;
import struct.Situation;
import browser.CredentialCookies;
import openings.OpeningTree;
import dict.Dictionary;
import haxe.ui.events.UIEvent;
import haxe.ui.components.OptionBox;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.TextField;
import haxe.ui.containers.ScrollView;
import struct.PieceColor;
import js.html.URLSearchParams;
import js.Cookie;
import struct.PieceType;
import openfl.Assets;
import haxe.Timer;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import openfl.system.Capabilities;
import haxe.ui.Toolkit;
import openfl.display.SimpleButton;
import js.Browser;
import tests.UITest;
import openfl.display.Sprite;
import gfx.screens.Analysis;
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

	private function onConnected()
	{
		//TODO: Fill (phase 2 according to notes)
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
}

package;

import assets.StandaloneAssetPath;
import gfx.preloader.DefaultPreloader;
import haxe.ui.HaxeUIApp;
import tests.Interceptor;
import browser.Blinker;
import gfx.ScreenNavigator;
import net.shared.dataobj.GreetingResponseData;
import tests.SimpleTests;
import gfx.basic_components.AutosizingLabel;
import struct.ChallengeParams;
import serialization.GameLogParser;
import utils.Changelog;
import gfx.screens.OpenChallengeJoining;
import gfx.Dialogs;
import tests.ui.analysis.TAnalysisScreen;
import haxe.ui.locale.LocaleManager;
import net.shared.PieceColor;
import utils.TimeControl;
import net.Requests;
import js.html.URLSearchParams;
import browser.CredentialCookies;
import gfx.SceneManager;
import gfx.screens.Analysis;
import gfx.screens.LanguageSelectIntro;
import haxe.ui.Toolkit;
import js.Browser;
import openings.OpeningTree;
import tests.UITest;

using StringTools;

/**
	This class contains the entry point of a program followed
	by all the necessary initialization.

	The file is structured in a waterfall manner: as you go
	through all of the initialization steps, you descend lower
	and lower.
**/
class Main
{
	public static var app:HaxeUIApp;

	public static function main() 
    {
        app = new HaxeUIApp();
        app.preloaderClass = DefaultPreloader;
		app.icon = NormalFavicon;
        app.ready(onAppReady);
    }

	private static function onAppReady()
	{
		init();
		deriveLanguage();
	}

	/**
		Some purely technical aspects for the app to work correctly
	**/
	private static function init() 
	{
		Browser.window.onpopstate = ScreenNavigator.navigate;
		Browser.document.addEventListener('contextmenu', event -> event.preventDefault());
		Browser.document.addEventListener('wheel', event -> {
			if (event.ctrlKey)
				event.preventDefault();
		}, true);
		Blinker.init();
		OpeningTree.init();
		Changelog.init();
		Config.init();

		#if debug
		Interceptor.init();
		#end

		var scene = SceneManager.launch();
		app.addComponent(scene);
		app.start();
	}

	/**
		Attempt to load user's language preference from their cookies.
		If no exist (usually when it's their first visit), ask user to choose
	**/
	private static function deriveLanguage() 
	{
		var langInitializedFromCookie:Bool = Preferences.language.load();

		if (langInitializedFromCookie)
			onLanguageReady();
		else
			SceneManager.toScreen(LanguageSelectIntro(onLanguageReady));
	}

	/**
		Set locale and finally attempt to connect
	**/
	private static function onLanguageReady() 
	{
		if (Preferences.language.get() == RU)
			LocaleManager.instance.language = "ru";
		else
			LocaleManager.instance.language = "en";

		Networker.launch();
		//test();
	}

	/**
		Method called instead of Networker.launch() during testing
	**/
	private static function test()
	{
		Networker.ignoreEmitCalls = true;
		LoginManager.imitateLoggedState("gulvan");
		//Your testing code here (refer to `tests` package)
	}
}

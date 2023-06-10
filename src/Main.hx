package;

import net.shared.openings.OpeningDatabase;
import gfx.game.common.ComponentPageName;
import gfx.game.common.ComponentPageBuilder;
import gfx.popups.ChangelogDialog;
import haxe.ui.containers.dialogs.Dialog;
import assets.StandaloneAssetPath;
import gfx.preloader.DefaultPreloader;
import haxe.ui.HaxeUIApp;
import tests.Interceptor;
import browser.Blinker;
import gfx.scene.ScreenNavigator;
import net.shared.dataobj.GreetingResponseData;
import tests.SimpleTests;
import gfx.basic_components.AutosizingLabel;
import net.shared.dataobj.ChallengeParams;
import utils.Changelog;
import gfx.screens.OpenChallengeJoining;
import gfx.Dialogs;
import haxe.ui.locale.LocaleManager;
import net.shared.PieceColor;
import net.shared.TimeControl;
import net.Requests;
import js.html.URLSearchParams;
import browser.CredentialCookies;
import gfx.scene.SceneManager;
import gfx.screens.LanguageSelectIntro;
import haxe.ui.Toolkit;
import js.Browser;
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

        var builders:Array<ComponentPageBuilder> = [];
        for (a in ComponentPageName.createAll())
            builders.push(new ComponentPageBuilder(a));
        for (b in builders)
            trace(b);
    }

    private static function onAppReady()
    {
        init(start);
    }

    /**
        Some purely technical aspects for the app to work correctly
    **/
    private static function init(onInitFinished:Void->Void) 
    {
        Browser.window.onpopstate = ScreenNavigator.navigate;
        Browser.document.addEventListener('contextmenu', event -> event.preventDefault());
        Browser.document.addEventListener('wheel', event -> {
            if (event.ctrlKey)
                event.preventDefault();
        }, true);
        Browser.document.body.style.overflow = "auto";

        #if debug
        Interceptor.init();
        #end

        Blinker.init();
        OpeningDatabase.generate();
        Changelog.init();
        Config.init(onInitFinished);
    }

    /**
        Executed right after the initialization finishes completely
    **/
    private static function start()
    {
        var scene = SceneManager.launch();
        app.addComponent(scene);
        app.start();

        deriveLanguage();
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
            SceneManager.getScene().toScreen(LanguageSelectIntro(onLanguageReady));
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

        SceneManager.getScene().refreshLanguage();

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

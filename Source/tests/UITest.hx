package tests;

import tests.ui.utils.data.TestCaseInfo;
import tests.ui.DataKeeper;
import tests.ui.FieldTraverser;
import haxe.ui.core.Screen;
import tests.ui.utils.components.MainView;
import tests.ui.TestedComponent;
import browser.CredentialCookies;
import haxe.ui.core.Component;
import net.LoginManager;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import js.Cookie;
import haxe.ds.IntMap;
import js.Browser;
import haxe.ui.components.Label;
import haxe.rtti.Meta;
import haxe.Timer;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;
import haxe.ui.containers.VerticalButtonBar;
import openfl.display.Sprite;
import haxe.ui.containers.Box;
import haxe.ui.containers.ScrollView;
import gfx.components.SpriteWrapper;
import haxe.ui.containers.HBox;
using StringTools;

class UITest
{
    private static var mainView:MainView;

    //TODO: History

    public static function logHandledEvent(encodedEvent:String)
    {
        //TODO: Implement
    }

    public static function logEndpointCall()
    {
        //TODO: Implement
    }

    private static function initSinks()
    {
        Networker.ignoreEmitCalls = true;
        LoginManager.login = CredentialCookies.getLogin();
        if (LoginManager.login == null)
            LoginManager.login = "TesterPlayer";
    }

    public static function launchTest(component:TestedComponent)
    {
        initSinks();

        var traverser:FieldTraverser = new FieldTraverser(component);
        var fieldResults:FieldTraverserResults = traverser.traverse();

        DataKeeper.load();
        var storedData:TestCaseInfo = DataKeeper.get(Type.getClassName(Type.getClass(component)));

        mainView = new MainView(component, fieldResults, storedData);
        Screen.instance.addComponent(mainView);
    }
}
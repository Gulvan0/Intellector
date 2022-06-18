package tests;

import haxe.ui.HaxeUIApp;
import gfx.ScreenManager;
import openfl.Lib;
import tests.ui.utils.data.EndpointArgument;
import tests.ui.utils.data.MacroStep;
import tests.ui.utils.data.TestCaseInfo;
import tests.ui.DataKeeper;
import tests.ui.FieldTraverser;
import haxe.ui.core.Screen;
import tests.ui.utils.components.MainView;
import tests.ui.TestedComponent;
import browser.CredentialCookies;
import net.LoginManager;
using StringTools;

class UITest
{
    private static var currentTestCase:String;
    private static var mainView:MainView;

    private static var history:Array<MacroStep> = [];

    public static function getHistory():Array<MacroStep>
    {
        return history.copy();
    }

    public static function getCurrentTestCase():String
    {
        return currentTestCase;
    }

    public static function logHandledEvent(encodedEvent:String)
    {
        logStep(Event(encodedEvent));
    }

    public static function logEndpointCall(fieldName:String, args:Array<EndpointArgument>)
    {
        logStep(EndpointCall(fieldName, args));
    }

    public static function logStep(step:MacroStep)
    {
        history.push(step);
        mainView.appendToHistory(step);
    }

    private static function initSinks()
    {
        Networker.ignoreEmitCalls = true;
        LoginManager.login = CredentialCookies.getLogin();
        if (LoginManager.login == null)
            LoginManager.login = "TesterPlayer";
    }

    private static function onDataReady(component:TestedComponent) 
    {
        currentTestCase = Type.getClassName(Type.getClass(component)).split('.').pop();
        initSinks();

        var traverser:FieldTraverser = new FieldTraverser(component);
        var fieldResults:FieldTraverserResults = traverser.traverse();

        var storedData:TestCaseInfo = DataKeeper.get(currentTestCase);

        mainView = new MainView(component, fieldResults, storedData);
        Screen.instance.addComponent(mainView);
    }

    public static function launchTest(component:TestedComponent)
    {
        DataKeeper.load(onDataReady.bind(component));
    }
}
package gfx.screens;

import haxe.ui.core.Screen;
import haxe.ui.core.Component;
import net.GeneralObserver;
import net.ServerEvent;
import struct.PieceColor;
import haxe.ui.containers.VBox;
import js.Browser;
import dict.Dictionary;
import haxe.ui.components.Button;
import openfl.display.Sprite;
import gfx.components.Dialogs;
import browser.CredentialCookies;

enum MainMenuButton
{
    SendChallenge;
    OpenChallenge;
    AnalysisBoard;
    Spectate;
    Profile;
    Settings;
    LogOut;
}

//TODO: Needs total revamp (also XML-ize)
class MainMenu extends VBox implements IScreen
{
    private static var standardBtnWidth:Float = 200;

    public function onEntered()
    {
        //* Do nothing
    }

    public function onClosed()
    {
        //* Do nothing
    }

    public function menuHidden():Bool
    {
        return false;
    }

    public function asComponent():Component
    {
        return this;
    }

    //TODO: Change the body of the following two functions and the logic behind their usage

    private function onDirectChallengeParamsSpecified(callee:String, startSecs:Int, bonusSecs:Int, color:PieceColor)
    {
        var colorName = color.getName();
        Networker.emitEvent(CreateDirectChallenge(callee, startSecs, bonusSecs, colorName));
    }

    private function onOpenChallengeParamsSpecified(startSecs:Int, bonusSecs:Int, color:Null<PieceColor>)
    {
        var colorName = color.getName();
        Networker.emitEvent(CreateOpenChallenge(startSecs, bonusSecs, colorName));
    }

    private function onSendChallenge(e) 
    {
        var response = Browser.window.prompt(Dictionary.getPhrase(ENTER_CALLEE));

        if (response != null)
			Dialogs.specifyChallengeParams(onDirectChallengeParamsSpecified.bind(response), ()->{});
    }

    private function onOpenChallenge(e) 
    {
        Dialogs.specifyChallengeParams(onOpenChallengeParamsSpecified, ()->{});
    }

    private function onAnalysisBoard(e) 
    {
        //TODO: Rewrite ||| ScreenManager.toScreen(Analysis);
    }

    private function onSpectate(e) 
    {
        var response = Browser.window.prompt(Dictionary.getPhrase(ENTER_SPECTATED));

        if (response != null)
            Networker.emitEvent(Spectate(response)); //TODO: Is an answer to this being processed correctly
    }

    
    private function onSettings(e) 
    {
        //TODO: Rewrite completely 
        //ScreenManager.toScreen(new Settings());
    }

    private function onProfile(e) 
    {
        var response = Browser.window.prompt(Dictionary.getPhrase(ENTER_PROFILE_OWNER));

        if (response != null)
            ScreenManager.toScreen(PlayerProfile(response));
    }

    private function onLogOut(e) 
    {
        CredentialCookies.removeLoginDetails();
		Networker.dropConnection();
    }
    
    private function createBtn(type:MainMenuButton):Button
    {
        var btn = new Button();
		btn.width = type != LogOut? standardBtnWidth : standardBtnWidth / 2;
        btn.text = dict.Utils.getMainMenuBtnText(type);
        btn.horizontalAlign = 'center';

        btn.onClick = switch type 
        {
            case SendChallenge: onSendChallenge;
            case OpenChallenge: onOpenChallenge;
            case AnalysisBoard: onAnalysisBoard;
            case Spectate: onSpectate;
            case Profile: onProfile;
            case Settings: onSettings;
            case LogOut: onLogOut;
        };
        return btn;
    }

    public function new() 
	{
        super();
		var mainMenu = new VBox();
		mainMenu.width = 200;

        for (type in MainMenuButton.createAll())
		    mainMenu.addComponent(createBtn(type));

		mainMenu.x = (Screen.instance.width - mainMenu.width) / 2;
		mainMenu.y = 100;
		addComponent(mainMenu);
    }
}
package gfx.screens;

import struct.PieceColor;
import haxe.ui.containers.VBox;
import js.Browser;
import dict.Dictionary;
import haxe.ui.components.Button;
import openfl.display.Sprite;

enum MainMenuButton
{
    SendChallenge;
    OpenChallenge;
    AnalysisBoard;
    Spectate;
    Settings;
    LogOut;
}

class MainMenu extends Sprite
{
    private static var standardBtnWidth:Float = 200;

    private function onSendChallenge(e) 
    {
        var response = Browser.window.prompt(Dictionary.getPhrase(ENTER_CALLEE));

        if (response != null)
        {
            var onSpecified = Networker.sendChallenge.bind(response);
			Dialogs.specifyChallengeParams(onSpecified, ()->{});
        }
    }

    private function onOpenChallenge(e) 
    {
        var onSpecified = (startSecs:Int, bonusSecs:Int, color:Null<PieceColor>) -> {
            Networker.sendOpenChallenge(startSecs, bonusSecs, color);
            ScreenManager.instance.toOpenChallengeHostingRoom(startSecs, bonusSecs, color);
        }

        Dialogs.specifyChallengeParams(onSpecified, ()->{});
    }

    private function onAnalysisBoard(e) 
    {
        ScreenManager.instance.toAnalysisBoard();
    }

    private function onSpectate(e) 
    {
        var response = Browser.window.prompt(Dictionary.getPhrase(ENTER_SPECTATED));

		if (response != null)
			Networker.spectate(response, ScreenManager.instance.toSpectation);
    }

    private function onSettings(e) 
    {
        ScreenManager.instance.toSettings();
    }

    private function onLogOut(e) 
    {
        url.Utils.removeLoginDetails();
		Networker.dropConnection();
    }

    public function new() 
	{
        super();
		var mainMenu = new VBox();
		mainMenu.width = 200;

        for (type in MainMenuButton.createAll())
		    mainMenu.addComponent(createBtn(type));

		mainMenu.x = (Browser.window.innerWidth - mainMenu.width) / 2;
		mainMenu.y = 100;
		addChild(mainMenu);
    }
    
    private function createBtn(type:MainMenuButton):Button
    {
        var btn = new Button();
		btn.width = type != LogOut? standardBtnWidth : standardBtnWidth / 2;
        btn.text = Dictionary.getMainMenuBtnText(type);
        btn.horizontalAlign = 'center';

        btn.onClick = switch type 
        {
            case SendChallenge: onSendChallenge;
            case OpenChallenge: onOpenChallenge;
            case AnalysisBoard: onAnalysisBoard;
            case Spectate: onSpectate;
            case Settings: onSettings;
            case LogOut: onLogOut;
        };
        return btn;
    }
}
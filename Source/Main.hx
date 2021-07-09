package;

import url.Utils;
import openings.OpeningTree;
import dict.Dictionary;
import haxe.ui.events.UIEvent;
import haxe.ui.components.OptionBox;
import Networker.OngoingBattleData;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.TextField;
import Networker.OpenChallengeData;
import Networker.MessageData;
import haxe.ui.containers.ScrollView;
import struct.PieceColor;
import Networker.TimeData;
import js.html.URLSearchParams;
import js.Cookie;
import struct.PieceType;
import openfl.Assets;
import Networker.GameOverData;
import Networker.MoveData;
import Networker.BattleData;
import haxe.Timer;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import openfl.system.Capabilities;
import haxe.ui.Toolkit;
import openfl.display.SimpleButton;
import js.Browser;
import openfl.display.Sprite;
using StringTools;

class Main extends Sprite
{
	public function new()
	{
		super();
		Browser.document.addEventListener('contextmenu', event -> event.preventDefault());
		Toolkit.init();
		OpeningTree.init();
		AssetManager.init();
		Utils.initSettings();
		Changes.initChangelog();
		addChild(new ScreenManager());
		Networker.connect(onConnected);
	}

	private function onConnected()
	{
		var searcher = new URLSearchParams(Browser.location.search);
		if (Cookie.exists("saved_login") && Cookie.exists("saved_password"))
			Networker.signin(Cookie.get("saved_login"), Cookie.get("saved_password"), onAutoLogin);
		else 
			onNoLogin();
	}

	private function onNoLogin()
	{
		switch Utils.getShallowSection() 
		{
			case OpenChallengeInvitation(issuer):
				Networker.getOpenChallenge(issuer, ScreenManager.instance.toOpenChallengeJoiningRoom, (d)->{ScreenManager.instance.toSignIn();}, ScreenManager.instance.toSignIn);
			default: 
				ScreenManager.instance.toSignIn();
		}
	}

	private function onAutoLogin(result:String)
	{
		function onGameInProcess(data:OngoingBattleData)
		{
			if (data.whiteLogin.toLowerCase() == Networker.login.toLowerCase())
			{
				data.whiteLogin = Networker.login;
				ScreenManager.instance.toGameReconnect(data);
			}
			else if (data.blackLogin.toLowerCase() == Networker.login.toLowerCase())
			{
				data.blackLogin = Networker.login;
				ScreenManager.instance.toGameReconnect(data);
			}
			else
				ScreenManager.instance.toSpectation(data);
		}

		if (result == 'success')
		{
			switch Utils.getShallowSection() 
			{
				case Main:
					ScreenManager.instance.toMain();
				case OpenChallengeInvitation(issuer):
					Networker.getOpenChallenge(issuer, ScreenManager.instance.toOpenChallengeJoiningRoom, onGameInProcess, ScreenManager.instance.toMain);
				case Game(id):
					Networker.getGame(id, onGameInProcess, (s)->{ScreenManager.instance.toMain();}, ScreenManager.instance.toMain);
			}
		}
		else
		{
			if (result != 'online')
				Utils.removeLoginDetails();
			ScreenManager.instance.toSignIn();
		}
	}
}

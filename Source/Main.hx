package;

import gameboard.Board;
import haxe.ui.containers.Box;
import gfx.components.SpriteWrapper;
import utils.AssetManager;
import gfx.components.gamefield.analysis.VariantTree;
import struct.Ply;
import struct.Variant;
import haxe.ui.components.Link;
import struct.Situation;
import analysis.ZobristHashing;
import analysis.PieceValues;
import url.Utils;
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
import openfl.display.Sprite;
using StringTools;

class Main extends Sprite
{
	public function new()
	{
		super();
		Browser.document.addEventListener('contextmenu', event -> event.preventDefault());
		Toolkit.init();
		Utils.initSettings();
		OpeningTree.init();
		PieceValues.initValues();
		ZobristHashing.init();
		AssetManager.init();
		Changes.initChangelog();
		addChild(new Board(Situation.starting()));
		//addChild(new ScreenManager());
		//Networker.connect(onConnected);
		//ScreenManager.instance.toAnalysisBoard(()->{});
	}

	/*private function onConnected()
	{
		if (Cookie.exists("saved_login") && Cookie.exists("saved_password"))
			Networker.signin(Cookie.get("saved_login"), Cookie.get("saved_password"), onAutoLogin, onOngoingGame);
		else 
			onNoLogin();
	}

	private function onNoLogin()
	{
		switch Utils.getShallowSection() 
		{
			case OpenChallengeInvitation(issuer):
				Networker.once('game_started', ScreenManager.instance.toGameStart);
				Networker.getOpenChallenge(issuer, ScreenManager.instance.toOpenChallengeJoiningRoom, (d)->{ScreenManager.instance.toSignIn();}, (d)->{ScreenManager.instance.toSignIn();}, ScreenManager.instance.toSignIn);
			default: 
				ScreenManager.instance.toSignIn();
		}
	}

	private function onOngoingGame(data:OngoingBattleData) 
	{
		if (data.whiteLogin.toLowerCase() == Networker.login.toLowerCase())
			data.whiteLogin = Networker.login;
		else if (data.blackLogin.toLowerCase() == Networker.login.toLowerCase())
			data.blackLogin = Networker.login;
		ScreenManager.instance.toGameReconnect(data);
	}

	private function onAutoLogin(result:String)
	{
		if (result == 'success')
		{
			switch Utils.getShallowSection() 
			{
				case Main:
					ScreenManager.instance.toMain();
				case OpenChallengeInvitation(issuer):
					Networker.once('game_started', ScreenManager.instance.toGameStart);
					Networker.getOpenChallenge(issuer, ScreenManager.instance.toOpenChallengeJoiningRoom, ScreenManager.instance.toSpectation, ScreenManager.instance.toGameReconnect, ScreenManager.instance.toMain);
				case Game(id):
					Networker.getGame(id, ScreenManager.instance.toSpectation, ScreenManager.instance.toGameReconnect, ScreenManager.instance.toRevisit.bind(id, _, ScreenManager.instance.toMain), ScreenManager.instance.toMain);
				case Profile(login):
					ScreenManager.instance.toProfile(login, ScreenManager.instance.toMain, ScreenManager.instance.toMain);
			}
		}
		else
		{
			Utils.removeLoginDetails();
			Networker.login = null;
			onNoLogin();
		}
	}*/
}

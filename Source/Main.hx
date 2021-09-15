package;

import gfx.components.analysis.VariantTree;
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
		Utils.initSettings();
		OpeningTree.init();
		PieceValues.initValues();
		ZobristHashing.init();
		AssetManager.init();
		Changes.initChangelog();
		addChild(new ScreenManager());
		//Networker.connect(onConnected);
		var emptyPly:Ply = new Ply();
		var variantRoot:Variant = new Variant();
		variantRoot.addChild(emptyPly, "1.Lh3");
		variantRoot.c("1.Lh3").addChild(emptyPly, "2.Lh4");
		variantRoot.c("1.Lh3").c("2.Lh4").addChild(emptyPly, "3.g3");
		variantRoot.c("1.Lh3").c("2.Lh4").addChild(emptyPly, "3.i2~h2");
		variantRoot.c("1.Lh3").c("2.Lh4").addChild(emptyPly, "3.Lb3");
		variantRoot.c("1.Lh3").addChild(emptyPly, "2.Lh5");
		variantRoot.c("1.Lh3").c("2.Lh5").addChild(emptyPly, "3.i2~h2");
		variantRoot.c("1.Lh3").c("2.Lh5").c("3.i2~h2").addChild(emptyPly, "4.LXh3");
		variantRoot.c("1.Lh3").addChild(emptyPly, "2.AXg1");

		var tree = new VariantTree(variantRoot, s->{trace(s);});
		tree.x = 50;
		tree.y = 50;
		addChild(tree);
		//ScreenManager.instance.toAnalysisBoard();
	}

	private function onConnected()
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
					Networker.getGame(id, ScreenManager.instance.toSpectation, ScreenManager.instance.toGameReconnect, ScreenManager.instance.toRevisit.bind(id), ScreenManager.instance.toMain);
				case Profile(login):
					Networker.getGames(login, ScreenManager.instance.toProfile.bind(login));
			}
		}
		else
		{
			Utils.removeLoginDetails();
			Networker.login = null;
			onNoLogin();
		}
	}
}

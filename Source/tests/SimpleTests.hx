package tests;

import gfx.profile.simple_components.StudyFilterRect;
import gfx.profile.data.ProfileData;
import gfx.profile.complex_components.ProfileHeader;
import gfx.Dialogs;
import net.shared.MiniProfileData;
import gfx.profile.simple_components.PlayerLabel;
import gfx.profile.complex_components.FriendList;
import haxe.ui.containers.HBox;
import haxe.ui.containers.Box;
import gfx.basic_components.Square;
import haxe.ui.containers.ScrollView;
import gfx.profile.simple_components.FriendListEntry;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import utils.AssetManager;
import gfx.basic_components.AnnotatedImage;
import haxe.ui.core.Screen;
import gfx.basic_components.AutosizingLabel;

class SimpleTests 
{
	public static function square()
	{
		var bgColors:Array<Int> = [0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0xff00ff, 0x00ffff];
		var squares:Array<Square> = [];

		for (i in 0...4)
		{
			var sq:Square = new Square();
			sq.customStyle = {backgroundColor: bgColors[i], backgroundOpacity: 0.5, verticalAlign: 'center'};
			squares.push(sq);
		}

		squares[0].height = 100;
		squares[1].percentHeight = 100;
		squares[2].width = 100;
		squares[3].percentWidth = 100;

		var contents1:HBox = new HBox();
		contents1.percentWidth = 100;
		contents1.height = 150;
		contents1.customStyle = {borderSize: 2, borderColor: 0x666666};
		for (i in 0...2)
			contents1.addComponent(squares[i]);

		var contents2:VBox = new VBox();
		contents2.percentHeight = 100;
		contents2.width = 150;
		contents2.customStyle = {borderSize: 2};
		for (i in 2...4)
			contents2.addComponent(squares[i]);

		var vbox:VBox = new VBox();
		vbox.percentWidth = 75;
		vbox.percentHeight = 75;
		vbox.verticalAlign = 'center';
		vbox.horizontalAlign = 'center';
		vbox.addComponent(contents1);
		vbox.addComponent(contents2);
		
		var box:Box = new Box();
		box.percentWidth = 100;
		box.percentHeight = 100;
		box.addComponent(vbox);

		Screen.instance.addComponent(box);
	}

    public static function autosizingLabel()
    {
		var v = new AutosizingLabel();
		v.customStyle = {backgroundColor: 0xff0000, backgroundOpacity: 0.5};
		v.percentWidth = 100;
		v.text = "Lorem ipsum dolor sit amet";
		v.horizontalAlign = 'center';
		v.verticalAlign = 'center';
		Screen.instance.addComponent(v);
	}
	
	public static function annotatedImage()
	{
		var vbox:VBox = new VBox();
		vbox.percentWidth = 100;
		vbox.verticalAlign = "center";

		var images:Array<AnnotatedImage> = [
			new AnnotatedImage(Exact(500), Exact(100), AssetManager.timeControlPath(Blitz), "3+2", "Blitz"),
			new AnnotatedImage(Auto, Exact(100), AssetManager.timeControlPath(Rapid), "10+15", "Rapid"),
			new AnnotatedImage(Percent(50), Exact(100), AssetManager.timeControlPath(Correspondence), "Correspondence")
		];

		for (image in images)
		{
			image.customStyle = {horizontalAlign: 'center', backgroundColor: 0xff0000, backgroundOpacity: 0.5};

			var newStyle:Style = image.img.customStyle.clone();
			newStyle.backgroundColor = 0xffff00;
			newStyle.backgroundOpacity = 0.5;
			image.img.customStyle = newStyle;
	
			var newStyle:Style = image.lbl.customStyle.clone();
			newStyle.backgroundColor = 0xffff00;
			newStyle.backgroundOpacity = 0.5;
			image.lbl.customStyle = newStyle;

			vbox.addComponent(image);
		}

		Screen.instance.addComponent(vbox);
	}

	public static function friendList()
	{
		var fl:FriendList = new FriendList();
		fl.percentWidth = 50;
		fl.height = 50;
		fl.percentContentHeight = 100;
		fl.horizontalAlign = 'center';
		fl.verticalAlign = 'center';
		fl.fill([
			{login: "gulvan", status: Online},
			{login: "kazvixx", status: Offline(20)},
			{login: "kartoved", status: Offline(123456)},
			{login: "superqwerty", status: InGame},
			{login: "kaz", status: Offline(12345678)}
		]);

		var box:Box = new Box();
		box.percentWidth = 100;
		box.percentHeight = 100;
		box.addComponent(fl);

		Screen.instance.addComponent(box);
	}

	public static function miniProfile()
	{
		var data:MiniProfileData = new MiniProfileData();
		data.gamesCntByTimeControl = [
			Hyperbullet => 0,
			Bullet => 20,
			Blitz => 3,
			Rapid => 228,
			Classic => 0,
			Correspondence => 1
		];
		data.elo = [
			Hyperbullet => None,
			Bullet => Normal(1123),
			Blitz => Provisional(1964),
			Rapid => Normal(1556),
			Classic => None,
			Correspondence => Provisional(1520)
		]; 
		data.isFriend = false;
		data.status = InGame;

		Dialogs.miniProfile("gulvan", data);
	}

	public function playerLabel()
	{
		var fl:PlayerLabel = new PlayerLabel(Exact(50), "gulvan", Normal(2300), true);
		fl.horizontalAlign = 'center';
		fl.verticalAlign = 'center';

		var box:Box = new Box();
		box.percentWidth = 100;
		box.percentHeight = 100;
		box.addComponent(fl);

		Screen.instance.addComponent(box);
	}

	public static function profileHeader()
	{
		var data:ProfileData = new ProfileData();
		data.gamesCntByTimeControl = [
			Hyperbullet => 0,
			Bullet => 20,
			Blitz => 3,
			Rapid => 228,
			Classic => 0,
			Correspondence => 1
		];
		data.elo = [
			Hyperbullet => None,
			Bullet => Normal(1123),
			Blitz => Provisional(1964),
			Rapid => Normal(1556),
			Classic => None,
			Correspondence => Provisional(1520)
		]; 
		data.isFriend = false;
		data.status = Offline(12345678);
		data.roles = [Admin];
		data.friends = [
			{login: "gulvan", status: Online},
			{login: "kazvixx", status: Offline(20)},
			{login: "kartoved", status: Offline(123456)},
			{login: "superqwerty", status: InGame},
			{login: "kaz", status: Offline(12345678)}
		];
		data.preloadedGames = [];
		data.preloadedStudies = [];
		data.gamesInProgress = [];
		data.totalPastGames = 252;
		data.totalStudies = 0;

		var fl:ProfileHeader = new ProfileHeader("kazvixx", data);
		fl.horizontalAlign = 'center';
		fl.verticalAlign = 'center';

		var box:Box = new Box();
		box.percentWidth = 100;
		box.percentHeight = 100;
		box.addComponent(fl);

		Screen.instance.addComponent(box);
	}

	public static function studyTagFilterRect()
	{
		var box:Box = new Box();
		box.percentWidth = 100;
		box.percentHeight = 100;

		var fl:StudyFilterRect;
		fl = new StudyFilterRect(Exact(30), "разобрать потом", () -> {box.removeComponent(fl);});
		fl.horizontalAlign = 'center';
		fl.verticalAlign = 'center';

		box.addComponent(fl);
		Screen.instance.addComponent(box);
	}
}
package tests;

import gfx.popups.IncomingChallengeDialog;
import gfx.profile.complex_components.MiniProfile;
import net.shared.dataobj.ChallengeData;
import haxe.ui.containers.Grid;
import gfx.menubar.ChallengeEntryRenderer;
import gfx.SceneManager;
import tests.data.ChallengeParameters;
import struct.ChallengeParams;
import tests.data.Variants;
import struct.Variant;
import gfx.popups.StudyParamsDialog;
import gfx.profile.complex_components.StudiesTab;
import gfx.basic_components.utils.DimValue;
import tests.data.StudyInfos;
import haxe.ui.core.Component;
import tests.data.ProfileInfos;
import tests.data.GameLogs;
import gfx.profile.simple_components.TimeControlFilterDropdown;
import gfx.common.GameWidget;
import gfx.common.GameWidget.GameWidgetData;
import net.shared.dataobj.GameInfo;
import net.shared.dataobj.StudyInfo;
import gfx.profile.simple_components.StudyWidget;
import gfx.profile.complex_components.StudyTagList;
import gfx.profile.simple_components.StudyTagLabel;
import gfx.profile.complex_components.StudyFilterList;
import gfx.profile.simple_components.StudyFilterRect;
import net.shared.dataobj.ProfileData;
import gfx.profile.complex_components.ProfileHeader;
import gfx.Dialogs;
import net.shared.dataobj.MiniProfileData;
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
	private static var box:Box;

	private static var traceArg:Dynamic->Void = arg -> {trace(arg);};

	private static function add(comp:Component, ?wrapperWidth:DimValue, ?wrapperHeight:DimValue)
	{
		comp.horizontalAlign = 'center';
		comp.verticalAlign = 'center';

		box = new Box();
		box.percentWidth = 100;
		box.percentHeight = 100;

		if (wrapperWidth != null || wrapperHeight != null)
		{
			var wrapperBox:Box = new Box();
			wrapperBox.horizontalAlign = 'center';
			wrapperBox.verticalAlign = 'center';

			if (wrapperWidth != null)
				assignWidth(wrapperBox, wrapperWidth);

			if (wrapperHeight != null)
				assignHeight(wrapperBox, wrapperHeight);

			wrapperBox.addComponent(comp);
			box.addComponent(wrapperBox);
		}
		else
			box.addComponent(comp);

		Screen.instance.addComponent(box);
	}

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
		vbox.addComponent(contents1);
		vbox.addComponent(contents2);
		
		add(vbox);
	}

    public static function autosizingLabel()
    {
		var v = new AutosizingLabel();
		v.customStyle = {backgroundColor: 0xff0000, backgroundOpacity: 0.5};
		v.percentWidth = 100;
		v.text = "Lorem ipsum dolor sit amet";
		add(v);
	}
	
	public static function annotatedImage()
	{
		var vbox:VBox = new VBox();
		vbox.percentWidth = 100;

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

		add(vbox);
	}

	public static function friendList()
	{
		var comp:FriendList = new FriendList(Percent(50), 50);
		comp.fill(ProfileInfos.friendList1());
		add(comp);
	}

	public static function miniProfile()
	{
		Dialogs.getQueue().add(new MiniProfile("gulvan", ProfileInfos.miniData1()));
	}

	public function playerLabel()
	{
		var comp:PlayerLabel = new PlayerLabel(Exact(50), "gulvan", Normal(2300), true);
		add(comp);
	}

	public static function profileHeader()
	{
		var comp:ProfileHeader = new ProfileHeader("kazvixx", ProfileInfos.data1());
		add(comp);
	}

	public static function studyTagFilterRect()
	{
		var comp:StudyFilterRect = null;
		comp = new StudyFilterRect(Exact(30), StudyInfos.tag(1), () -> {box.removeComponent(comp);}, PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP);
		add(comp);
	}

	public static function studyFilterList()
	{
		var tags:Array<String> = [];

		function onAdded(tag:String)
		{
			tags.push(tag);
			trace(tags);
		}

		function onRemoved(tag:String)
		{
			tags.remove(tag);
			trace(tags);
		}

		function onCleared()
		{
			tags = [];
			trace(tags);
		}

		var comp:StudyFilterList = new StudyFilterList(Percent(50), 36, onAdded, onRemoved, onCleared, PROFILE_TAG_FILTERS_PREPENDER, PROFILE_TAG_NO_FILTERS_PLACEHOLDER_TEXT, PROFILE_ADD_TAG_FILTER_BTN_TEXT, PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP, PROFILE_CLEAR_TAG_FILTERS_BTN_TEXT, PROFILE_TAG_FILTER_PROMPT_QUESTION_TEXT);
		add(comp);
	}

	public static function studyTagLabel()
	{
		var comp:StudyTagLabel = new StudyTagLabel(Exact(30), StudyInfos.tag(1), () -> {trace(1);});
		add(comp);
	}

	public static function studyTagList()
	{
		var comp:StudyTagList = new StudyTagList(Percent(50), 36, StudyInfos.tagList1(), s -> {trace(s);});
		add(comp);
	}

	public static function studyWidget()
	{
		var data:StudyWidgetData = {
			id: 12,
			ownerLogin: LoginManager.getLogin(),
			info: StudyInfos.info1(),
			onStudyClicked: () -> {trace('Clicked');},
			onTagSelected: tag -> {trace('Tag: $tag');},
			onEditPressed: () -> {trace('Edit requested');},
			onDeletePressed: () -> {trace('Delete requested');}
		};

		var comp:StudyWidget = new StudyWidget();
		comp.data = data;
		add(comp, Percent(50), Exact(200));
	}

	public static function gameWidget()
	{
		var info:GameInfo = new GameInfo();
		info.id = 228;
		info.log = GameLogs.log1();

		var data:GameWidgetData = {
			info: info,
			watchedLogin: "gulvan",
			onClicked: () -> {trace('Clicked');}
		};

		var comp:GameWidget = new GameWidget();
		comp.data = data;
		add(comp, Percent(50), Exact(200));
	}

	public static function tcFilterDropdown()
	{
		var sampleProfileData:ProfileData = ProfileInfos.data1();
		var comp:TimeControlFilterDropdown = new TimeControlFilterDropdown(sampleProfileData.elo, sampleProfileData.gamesCntByTimeControl, sampleProfileData.totalPastGames, traceArg);
		add(comp);
	}

	public static function studyTab()
	{
		var comp:StudiesTab = new StudiesTab("gulvan", [
			111 => StudyInfos.info1(),
			23 => StudyInfos.info2(),
			21 => StudyInfos.info3()
		], 5);
		add(comp, Percent(50), Percent(90));
	}

	public static function newStudyDialog()
	{
		var mode:StudyParamsDialogMode = Create(Variants.variant1());
		Dialogs.getQueue().add(new StudyParamsDialog(mode));
	}

	public static function overwriteStudyDialog()
	{
		var mode:StudyParamsDialogMode = CreateOrOverwrite(Variants.variant1(), 23, StudyInfos.info1());
		Dialogs.getQueue().add(new StudyParamsDialog(mode));
	}

	public static function editStudyDialog()
	{
		var mode:StudyParamsDialogMode = Edit(111, StudyInfos.info1(), traceArg);
		Dialogs.getQueue().add(new StudyParamsDialog(mode));
	}

	public static function incomingChallengeDialog(i:Int)
	{
		var challengeParams:ChallengeParams = switch i
		{
			case 0: ChallengeParameters.incomingDirectBlitzCustomized();
			case 1: ChallengeParameters.incomingDirectRapidRated();
			case 2: ChallengeParameters.incomingDirectCorrespondenceUnrated();
			default: ChallengeParameters.incomingDirectHyperbulletWhiteAcceptor();
		}

		var challengeData:ChallengeData = new ChallengeData();
		challengeData.id = 42;
		challengeData.serializedParams = challengeParams.serialize();
		challengeData.ownerLogin = "kaz";
		challengeData.ownerELO = Normal(1345);

		Dialogs.getQueue().add(new IncomingChallengeDialog(challengeData, ()->{}));
	}

	public static function challengeEntryRenderer(i:Int) 
	{
		var contentBox:Grid = new Grid();
		contentBox.columns = 2;
		for (i in 0...7)
		{
			var challengeParams:ChallengeParams = switch i
			{
				case 0: ChallengeParameters.incomingDirectBlitzCustomized();
				case 1: ChallengeParameters.outgoingDirect();
				case 2: ChallengeParameters.incomingDirectRapidRated();
				case 3: ChallengeParameters.outgoingPublic();
				case 4: ChallengeParameters.incomingDirectCorrespondenceUnrated();
				case 5: ChallengeParameters.outgoingByLink();
				default: ChallengeParameters.incomingDirectHyperbulletWhiteAcceptor();
			};

			var challengeData:ChallengeData = new ChallengeData();
			challengeData.id = 12;
			challengeData.serializedParams = challengeParams.serialize();
			challengeData.ownerLogin = i % 2 == 0? "kaz" : "gulvan";
			challengeData.ownerELO = Provisional(1250);

			var innerBox:Box = new Box();
			assignWidth(innerBox, Exact(325));

			var comp = new ChallengeEntryRenderer();
			comp.data = challengeData;

			innerBox.addComponent(comp);
			contentBox.addComponent(innerBox);
		}
		
		add(contentBox);
	}

	@:access(gfx.SceneManager.scene)
	public static function challengeMenuEvent(i:Int) 
	{
		var challengeParams:ChallengeParams = switch i
		{
			case 0: ChallengeParameters.incomingDirectBlitzCustomized();
			case 1: ChallengeParameters.incomingDirectRapidRated();
			case 2: ChallengeParameters.incomingDirectCorrespondenceUnrated();
			case 3: ChallengeParameters.incomingDirectHyperbulletWhiteAcceptor();
			case 4: ChallengeParameters.outgoingDirect();
			case 5: ChallengeParameters.outgoingPublic();
			default: ChallengeParameters.outgoingByLink();
		}

		var challengeData:ChallengeData = new ChallengeData();
		challengeData.id = 12;
		challengeData.serializedParams = challengeParams.serialize();
		challengeData.ownerLogin = i < 4? "kaz" : "gulvan";
		challengeData.ownerELO = Provisional(1250);

		SceneManager.scene.challengesMenu.appendEntry(challengeData);
	}

	public static function simpleAnalysis()
	{
		SceneManager.toScreen(Analysis(Variants.variant1().serialize(), 0, null, null));
	}

	public static function studyAnalysis()
	{
		SceneManager.toScreen(Analysis(Variants.variant1().serialize(), 0, 111, StudyInfos.info1()));
	}
}
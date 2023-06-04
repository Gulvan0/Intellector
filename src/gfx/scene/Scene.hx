package gfx.scene;

import gfx.menu.MenuItem;
import gfx.menu.MenuSection;
import gfx.menu.MenuBar;
import gfx.menu.MenuItemName;
import haxe.ui.core.Component;
import dict.Phrase;
import assets.Audio;
import gfx.popups.OpenChallengeCreated;
import gfx.popups.IncomingChallengeDialog;
import gfx.popups.Settings;
import gfx.popups.LogIn;
import gfx.popups.ChallengeParamsDialog;
import browser.Blinker;
import js.Browser;
import browser.Url;
import net.shared.dataobj.ChallengeData;
import haxe.ui.components.Image;
import net.shared.dataobj.SendChallengeResult;
import net.shared.dataobj.ChallengeParams;
import haxe.ui.containers.SideBar;
import dict.Dictionary;
import GlobalBroadcaster.IGlobalEventObserver;
import GlobalBroadcaster.GlobalEvent;
import net.INetObserver;
import net.shared.ServerEvent;
import utils.StringUtils;
import net.Requests;
import gfx.Dialogs;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import haxe.ui.components.Button;
import haxe.ui.core.Screen as HaxeUIScreen;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/scene/scene.xml'))
class Scene extends VBox implements INetObserver implements IGlobalEventObserver implements IPublicScene
{
    private var currentScreen:Null<Screen> = null;

    private var menubar:MenuBar;

    public function isUserParticipatingInOngoingFiniteGame():Bool
    {
        return currentScreen?.isUserParticipatingInOngoingFiniteGame() ?? false;
    }

    public function resize()
    {
        menubar.resize();
    }

    public function refreshTitleAndUrl()
    {
        var titlePhrase:Null<Phrase> = currentScreen.getTitle();
        var titleStr:Null<String> = titlePhrase == null? null : Dictionary.getPhrase(titlePhrase);

        Url.setPath(currentScreen.getURLPath(), titleStr);
    }

    public function refreshLanguage() 
    {
        menubar.refreshLanguage();
    }

    public function returnToMainScene()
    {
        subscreenContainer.removeAllComponents();
        stack.selectedId = "mainScene";
    }

    public function displaySubscreen(subscreen:Component)
    {
        subscreenContainer.removeAllComponents();
        subscreenContainer.addComponent(subscreen);
        stack.selectedId = "subscreenContainer";
    }

    public function removeEntryFromChallengeList(challengeID:Int)
    {
        menubar.challengesMenu.removeEntryByID(challengeID);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event
        {
            case GoToGame(data):
                //TODO: Rewrite, add spectation case?
                /*var parsedData:GameLogParserOutput = GameLogParser.parse(logPreamble);

                if (parsedData.isPlayerParticipant())
                {
                    Dialogs.getQueue().closeGroup(RemovedOnGameStarted);
                    Blinker.blink(GameStarted);
                    if (parsedData.timeControl.getType() != Correspondence)
                        setIngameStatus(true);

                    var opponentLogin:String = parsedData.getPlayerOpponentRef();
                    challengesMenu.removeOwnEntries();
                    challengesMenu.removeEntriesByPlayer(opponentLogin);
                }*/
                /*if (parsedData.isPlayerParticipant())
                {
                    FollowManager.stopFollowing();
                    constructor = New(parsedData.whiteRef, parsedData.blackRef, parsedData.elo, parsedData.timeControl, parsedData.startingSituation, parsedData.datetime);
                }
                else
                {
                    FollowManager.followedGameID = gameID;
                    constructor = Ongoing(parsedData, null, FollowManager.getFollowedPlayerLogin());
                }
                toScreen(LiveGame(gameID, constructor));*/
            default:
        }
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event
        {
            case ModalDialogShown:
                disabled = true;
            case ModalDialogRemoved:
                disabled = false;
            default:
        }
    }

    public function toScreen(initializer:Null<ScreenInitializer>)
    {
        if (currentScreen != null)
        {
            currentScreen.onClosed();
            content.removeComponent(currentScreen);
        }

        if (initializer == null)
        {
            currentScreen = null;
            Url.clear();
        }
        else
        {
            currentScreen = Screen.build(initializer);

            menubar.hidden = currentScreen.menuHidden;
            content.addComponent(currentScreen);
            
            refreshTitleAndUrl();
            if (Networker.isConnectedToServer())
                Networker.emitEvent(PageUpdated(currentScreen.getPage()));

            currentScreen.onEntered();
        }
    }

    private function onSiteNamePressed() 
    {
        toScreen(MainMenu);
    }

    private function onMenuItemSelected(itemName:MenuItemName)
    {
        switch itemName 
        {
            case CreateChallenge:
                var displayChallengeParamsDialog:Void->Void = () -> {
                    Dialogs.getQueue().add(new ChallengeParamsDialog());
                };

                if (!LoginManager.isLogged())
                    Dialogs.getQueue().add(new LogIn(displayChallengeParamsDialog));
                else
                    displayChallengeParamsDialog();
            case OpenChallenges:
                toScreen(MainMenu);
            case PlayVersusBot:
                var displayChallengeParamsDialog:Void->Void = () -> {
                    Dialogs.getQueue().add(new ChallengeParamsDialog(ChallengeParams.anacondaChallengeParams()));
                };

                if (!LoginManager.isLogged())
                    Dialogs.getQueue().add(new LogIn(displayChallengeParamsDialog));
                else
                    displayChallengeParamsDialog();
            case CurrentGames:
                toScreen(MainMenu);
            case FollowPlayer:
                Dialogs.prompt(INPUT_PLAYER_LOGIN, All, FollowManager.followPlayer);
            case AnalysisBoard:
                toScreen(NewAnalysisBoard);
            case PlayerProfile:
                Dialogs.prompt(INPUT_PLAYER_LOGIN, All, Requests.getPlayerProfile.bind(_, null));
            case DiscordServer:
                Browser.window.open("https://discord.gg/f8chehcnV5", "_blank");
            case VKGroup:
                Browser.window.open("https://vk.com/intellectorgroup", "_blank");
            case VKChat:
                Browser.window.open("https://vk.me/join/7avlp3lMTWM4a/lIbWNjUUtS/G19c/QMygs=", "_blank");
        }
    }

    public function new()
    {
        super();

        var sections:Array<MenuSection> = [Play, Watch, Learn, Social];
        var itemNames:Map<MenuSection, Array<MenuItemName>> = [
            Play => [CreateChallenge, OpenChallenges, PlayVersusBot],
            Watch => [CurrentGames, FollowPlayer],
            Learn => [AnalysisBoard],
            Social => [PlayerProfile, DiscordServer, VKGroup, VKChat]
        ];
        var items:Map<MenuSection, Array<MenuItem>> = [for (k => v in itemNames) k => v.map(name -> new MenuItem(name))];

        menubar = new MenuBar(sections, items, onMenuItemSelected, onSiteNamePressed);

        mainScene.addComponentAt(menubar, 0);
    }

}
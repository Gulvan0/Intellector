package gfx.screens;

import net.LoginManager;
import net.EventProcessingQueue.INetObserver;
import net.ServerEvent;
import utils.CallbackTools;
import haxe.ui.containers.HBox;
import gfx.components.Shapes;
import haxe.Json;
import haxe.ui.components.Link;
import js.Browser;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Component;
import haxe.ui.components.Button;
import browser.URLEditor;
import openfl.text.TextFormat;
import openfl.text.TextField;
import dict.Dictionary;
import serialization.GameLogParser;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
using StringTools;

typedef GameOverview = 
{
    var id:Int;
    var whiteLogin:String;
    var blackLogin:String;
    var winnerColorLetter:String;
    var outcomeCode:String;
}

typedef StudyOverview = 
{
    var id:Int;
    var data:StudyData;
}

typedef StudyData = 
{
    var name:String;
    var author:String;
    var variantStr:String;
}

class PlayerProfile extends Screen implements INetObserver
{
    private var profileOwnerLogin:String;

    private var gamesBox:VBox;
    private var studiesBox:VBox;

    private var gamesPrevBtn:Button;
    private var gamesNextBtn:Button;
    private var studiesPrevBtn:Button;
    private var studieNextBtn:Button;

    private var gamelistComponents:Array<Component> = [];
    private var studylistComponents:Array<Component> = [];

    private var requestedGameID:Int;

    private var gamePaginationAfter:Int = 0;
    private var gamePaginationPageSize:Int = 20;
    private var studyPaginationAfter:Int = 0;
    private var studyPaginationPageSize:Int = 20;

    public function handleNetEvent(event:ServerEvent)
    {
        /*switch event 
        {
            case GameIsOver(log):
                ...
            case GamesList(listStr, hasNext, hasPrev):
                populateGames(listStr);
                gamesPrevBtn.disabled = !hasPrev;
                gamesNextBtn.disabled = !hasNext;
            case StudiesList(listStr, hasNext, hasPrev):
                populateStudies(listStr);
                studiesPrevBtn.disabled = !hasPrev;
                studieNextBtn.disabled = !hasNext;
            case PlayerNotFound:
                ScreenManager.toScreen(MainMenu);
                Browser.window.alert(Dictionary.getPhrase(PLAYER_NOT_FOUND));
            default:
        }*/
    }

    public override function onEntered()
    {
        Networker.eventQueue.addObserver(this);
        Networker.emitEvent(GetPlayerGames(profileOwnerLogin, gamePaginationAfter, gamePaginationPageSize));
        Networker.emitEvent(GetPlayerStudies(profileOwnerLogin, studyPaginationAfter, studyPaginationPageSize));
    }

    public override function onClosed()
    {
        Networker.eventQueue.removeObserser(this);
    }

    private function onGamesPrev(e) 
    {
        gamePaginationAfter -= gamePaginationPageSize;
        Networker.emitEvent(GetPlayerGames(profileOwnerLogin, gamePaginationAfter, gamePaginationPageSize));
    }

    private function onGamesNext(e) 
    {
        gamePaginationAfter += gamePaginationPageSize;
        Networker.emitEvent(GetPlayerGames(profileOwnerLogin, gamePaginationAfter, gamePaginationPageSize));
    }

    private function onStudiesPrev(e) 
    {
        studyPaginationAfter -= studyPaginationPageSize;
        Networker.emitEvent(GetPlayerStudies(profileOwnerLogin, studyPaginationAfter, studyPaginationPageSize));
    }

    private function onStudiesNext(e) 
    {
        studyPaginationAfter += studyPaginationPageSize;
        Networker.emitEvent(GetPlayerStudies(profileOwnerLogin, studyPaginationAfter, studyPaginationPageSize));
    }

    public function populateGames(gamelistStr:String) 
    {
        var gamelist:Array<GameOverview> = Json.parse(gamelistStr);

        if (Lambda.empty(gamelist))
            return;

        for (comp in gamelistComponents)
            gamesBox.removeComponent(comp);
        gamelistComponents = [];

        for (overview in gamelist)
        {
            var winner = GameLogParser.decodeColor(overview.winnerColorLetter);
            var outcome = GameLogParser.decodeOutcome(overview.outcomeCode);
            var text = overview.id + '. ${overview.whiteLogin} vs ${overview.blackLogin} • ' + dict.Utils.getMatchlistResultText(winner, outcome);

            var link:Link = gameLink(text, overview.id);
            gamesBox.addComponent(link);
            gamelistComponents.push(link);

            var spacer = Shapes.vSpacer(4);
            gamesBox.addComponent(spacer);
            gamelistComponents.push(spacer);
        }
    }

    public function populateStudies(studylistStr:String) 
    {
        var studylist:Array<StudyOverview> = Json.parse(studylistStr);

        if (Lambda.empty(studylist))
            return;

        for (comp in studylistComponents)
            studiesBox.removeComponent(comp);
        studylistComponents = [];

        for (overview in studylist)
        {
            var text:String = overview.id + ". " + overview.data.name;

            var link:Link = studyLink(text, overview);
            studiesBox.addComponent(link);
            studylistComponents.push(link);

            var spacer = Shapes.vSpacer(4);
            studiesBox.addComponent(spacer);
            studylistComponents.push(spacer);
        }
    }

    private function createGamesHeader() 
    {
        var gamesHeader:Label = new Label();
        gamesHeader.text = Dictionary.getPhrase(GAMES);
        gamesHeader.customStyle = {fontSize: 18, fontItalic: true};
        gamesHeader.horizontalAlign = 'center';

        gamesPrevBtn = new Button();
        gamesPrevBtn.text = "◄";
        gamesPrevBtn.width = 100;
        gamesPrevBtn.onClick = onGamesPrev;

        gamesNextBtn = new Button();
        gamesNextBtn.text = "►";
        gamesNextBtn.width = 100;
        gamesNextBtn.onClick = onGamesNext;

        var gamesControls:HBox = new HBox();
        gamesControls.horizontalAlign = 'center';
        gamesControls.addComponent(gamesPrevBtn);
        gamesControls.addComponent(gamesNextBtn);

        gamesBox.addComponent(gamesHeader);
        gamesBox.addComponent(gamesControls);
    }

    private function createStudiesHeader() 
    {
        var studiesHeader:Label = new Label();
        studiesHeader.text = Dictionary.getPhrase(STUDIES);
        studiesHeader.customStyle = {fontSize: 18, fontItalic: true};
        studiesHeader.horizontalAlign = 'center';

        studiesPrevBtn = new Button();
        studiesPrevBtn.text = "◄";
        studiesPrevBtn.width = 100;
        studiesPrevBtn.onClick = onStudiesPrev;

        studieNextBtn = new Button();
        studieNextBtn.text = "►";
        studieNextBtn.width = 100;
        studieNextBtn.onClick = onStudiesNext;

        var studiesControls:HBox = new HBox();
        studiesControls.horizontalAlign = 'center';
        studiesControls.addComponent(studiesPrevBtn);
        studiesControls.addComponent(studieNextBtn);

        studiesBox.addComponent(studiesHeader);
        studiesBox.addComponent(studiesControls);
    }

    public function new(playerLogin:String) 
    {
        super();
        profileOwnerLogin = playerLogin;

        var loginLabel:Label = new Label();
        loginLabel.text = playerLogin;
        loginLabel.customStyle = {fontSize: 32};
        loginLabel.horizontalAlign = 'center';

        gamesBox = new VBox();
        gamesBox.width = 550;
        createGamesHeader();

        studiesBox = new VBox();
        studiesBox.width = 550;
        createStudiesHeader();

        var contentHBox:HBox = new HBox();
        contentHBox.horizontalAlign = 'center';
        contentHBox.addComponent(gamesBox);
        contentHBox.addComponent(Shapes.hSpacer(30));
        contentHBox.addComponent(studiesBox);

        var mainBox:VBox = new VBox();
        mainBox.width = Browser.window.innerWidth;
        mainBox.addComponent(Shapes.vSpacer(25));
        mainBox.addComponent(loginLabel);
        mainBox.addComponent(Shapes.vSpacer(60));
        mainBox.addComponent(contentHBox);
        content.addComponent(mainBox);
    }

    private function gameLink(text:String, gameID:Int):Link
    {
        var link:Link = haxeuiLink(text);
        link.onClick = (e) -> {
            requestedGameID = gameID;
            Networker.emitEvent(GetGame(gameID));
        };
        return link;
    }

    private function studyLink(text:String, overview:StudyOverview):Link
    {
        var exploredStudyID:Null<Int> = null;
        if (LoginManager.isPlayer(overview.data.author))
            exploredStudyID = overview.id;

        var link:Link = haxeuiLink(text);
        link.onClick = (e) -> {ScreenManager.toScreen(Analysis(overview.data.variantStr, exploredStudyID, null));}; //Wrong way to do things (use name from overview)
        return link;
    }

    private function haxeuiLink(text:String):Link
    {
        var link:Link = new Link();
        link.text = text;
        link.width = 540;
        link.horizontalAlign = 'center';
        link.customStyle = {fontSize: 14, textAlign: 'center'};
        return link;
    }
}
package gfx.screens;

import utils.CallbackTools;
import haxe.ui.containers.HBox;
import gfx.components.Shapes;
import haxe.Json;
import haxe.ui.components.Link;
import js.Browser;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen;
import haxe.ui.core.Component;
import haxe.ui.components.Button;
import url.URLEditor;
import openfl.text.TextFormat;
import openfl.text.TextField;
import dict.Dictionary;
import serialization.GameLogDeserializer;
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

class PlayerProfile extends Sprite
{
    private var profileOwnerLogin:String;

    private var gamesBox:VBox;
    private var studiesBox:VBox;

    private var gamePaginationAfter:Int = 0;
    private var gamePaginationPageSize:Int = 20;
    private var studyPaginationAfter:Int = 0;
    private var studyPaginationPageSize:Int = 20;

    private function onGamesPrev(e) 
    {
        if (gamePaginationAfter < gamePaginationPageSize)
            return;
        
        var nextAfter:Int = gamePaginationAfter - gamePaginationPageSize;
        Networker.getGames(profileOwnerLogin, nextAfter, gamePaginationPageSize, listStr -> {
            if (listStr.length > 2)
            {
                populateGames(listStr);
                gamePaginationAfter = nextAfter;
            }
        }, () -> {});
    }

    private function onGamesNext(e) 
    {
        var nextAfter:Int = gamePaginationAfter + gamePaginationPageSize;
        Networker.getGames(profileOwnerLogin, nextAfter, gamePaginationPageSize, listStr -> {
            if (listStr.length > 2)
            {
                populateGames(listStr);
                gamePaginationAfter = nextAfter;
            }
        }, () -> {});
    }

    private function onStudiesPrev(e) 
    {
        if (studyPaginationAfter < studyPaginationPageSize)
            return;
        
        var nextAfter:Int = studyPaginationAfter - studyPaginationPageSize;
        Networker.getGames(profileOwnerLogin, nextAfter, studyPaginationPageSize, listStr -> {
            if (listStr.length > 2)
            {
                populateStudies(listStr);
                studyPaginationAfter = nextAfter;
            }
        }, () -> {});
    }

    private function onStudiesNext(e) 
    {
        var nextAfter:Int = studyPaginationAfter + studyPaginationPageSize;
        Networker.getGames(profileOwnerLogin, nextAfter, studyPaginationPageSize, listStr -> {
            if (listStr.length > 2)
            {
                populateStudies(listStr);
                studyPaginationAfter = nextAfter;
            }
        }, () -> {});
    }

    public function populateGames(gamelistStr:String) 
    {
        gamesBox.removeAllComponents();
        createGamesHeader();

        var gamelist:Array<GameOverview> = Json.parse(gamelistStr);
        for (overview in gamelist)
        {
            var winner = GameLogDeserializer.decodeColor(overview.winnerColorLetter);
            var outcome = GameLogDeserializer.decodeOutcome(overview.outcomeCode);
            var text = overview.id + '. ${overview.whiteLogin} vs ${overview.blackLogin} • ' + Dictionary.getMatchlistResultText(winner, outcome);

            var link:Link = gameLink(text, overview.id);
            gamesBox.addComponent(link);
            gamesBox.addComponent(Shapes.vSpacer(4));
        }
    }

    public function populateStudies(studylistStr:String) 
    {
        studiesBox.removeAllComponents();
        createStudiesHeader();

        var studylist:Array<StudyOverview> = Json.parse(studylistStr);
        for (overview in studylist)
        {
            var text:String = overview.id + ". " + overview.data.name;
            var link:Link = studyLink(text, overview);
            studiesBox.addComponent(link);
            studiesBox.addComponent(Shapes.vSpacer(4));
        }
    }

    private function createGamesHeader() 
    {
        var gamesHeader:Label = new Label();
        gamesHeader.text = Dictionary.getPhrase(GAMES);
        gamesHeader.customStyle = {fontSize: 18, fontItalic: true};
        gamesHeader.horizontalAlign = 'center';

        var lBtn:Button = new Button();
        lBtn.text = "◄";
        lBtn.width = 100;
        lBtn.onClick = onGamesPrev;

        var rBtn:Button = new Button();
        rBtn.text = "►";
        rBtn.width = 100;
        rBtn.onClick = onGamesNext;

        var gamesControls:HBox = new HBox();
        gamesControls.horizontalAlign = 'center';
        gamesControls.addComponent(lBtn);
        gamesControls.addComponent(rBtn);

        gamesBox.addComponent(gamesHeader);
        gamesBox.addComponent(gamesControls);
    }

    private function createStudiesHeader() 
    {
        var studiesHeader:Label = new Label();
        studiesHeader.text = Dictionary.getPhrase(STUDIES);
        studiesHeader.customStyle = {fontSize: 18, fontItalic: true};
        studiesHeader.horizontalAlign = 'center';

        var lBtn2:Button = new Button();
        lBtn2.text = "◄";
        lBtn2.width = 100;
        lBtn2.onClick = onStudiesPrev;

        var rBtn2:Button = new Button();
        rBtn2.text = "►";
        rBtn2.width = 100;
        rBtn2.onClick = onStudiesNext;

        var studiesControls:HBox = new HBox();
        studiesControls.horizontalAlign = 'center';
        studiesControls.addComponent(lBtn2);
        studiesControls.addComponent(rBtn2);

        studiesBox.addComponent(studiesHeader);
        studiesBox.addComponent(studiesControls);
    }

    public function new(playerLogin:String, onReturn:Void->Void) 
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
        addChild(mainBox);

        var returnBtn = new Button();
		returnBtn.width = 100;
		returnBtn.text = Dictionary.getPhrase(RETURN);
		returnBtn.onClick = CallbackTools.expand(onReturn);
            
        returnBtn.x = 10;
	    returnBtn.y = 10;
        addChild(returnBtn);
        
        Networker.getGames(playerLogin, gamePaginationAfter, gamePaginationPageSize, populateGames, onReturn);
        Networker.getStudies(playerLogin, studyPaginationAfter, studyPaginationPageSize, populateStudies, onReturn);
    }

    private function gameLink(text:String, gameID:Int):Link
    {
        var link:Link = haxeuiLink(text);
        link.onClick = (e) -> {Networker.getGame(gameID, (d)->{}, (d)->{}, ScreenManager.instance.toRevisit.bind(gameID, _,  ScreenManager.instance.toProfile.bind(profileOwnerLogin, ScreenManager.instance.toMain, ScreenManager.instance.toMain)), ()->{});};
        return link;
    }

    private function studyLink(text:String, overview:StudyOverview):Link
    {
        var link:Link = haxeuiLink(text);
        link.onClick = (e) -> {ScreenManager.instance.toAnalysisBoard(ScreenManager.instance.toProfile.bind(profileOwnerLogin, ScreenManager.instance.toMain, ScreenManager.instance.toMain), overview);};
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
package gfx.screens;

import js.Browser;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen;
import haxe.ui.core.Component;
import haxe.ui.components.Button;
import gfx.components.SpriteComponent;
import url.URLEditor;
import openfl.text.TextFormat;
import openfl.text.TextField;
import dict.Dictionary;
import serialization.GameLogDeserializer;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
using StringTools;

class PlayerProfile extends Sprite
{
    public function new(playerLogin:String, gamesList:String) 
    {
        super();
        var vbox:VBox = new VBox();
        
        var loginLabel:Label = new Label();
        loginLabel.text = playerLogin;
        loginLabel.customStyle = {fontSize: 18};
        vbox.addComponent(loginLabel);
        
        var gamesHeader:Label = new Label();
        gamesHeader.text = "Games";
        gamesHeader.customStyle = {fontSize: 14, fontBold: true};
        vbox.addComponent(gamesHeader);

        var scrollview:ScrollView = new ScrollView();
        scrollview.width = 530;
        scrollview.height = Browser.window.innerHeight - 200;

        var matchesInfo:Array<Array<String>> = [];
        for (line in gamesList.split(";"))
        {
            var trimmed:String = line.trim();
            if (trimmed.length > 0)
                matchesInfo.push(trimmed.split("#"));
        }
        matchesInfo.sort((i1, i2) -> Std.parseInt(i1[0]) - Std.parseInt(i2[0]));

        for (match in matchesInfo)
        {
            var winner = GameLogDeserializer.decodeColor(match[1].charAt(0));
            var outcome = GameLogDeserializer.decodeOutcome(match[1].substr(2, 3));
            var text =  match[0] + ". " + match[2].replace(":", " vs ") + " • " + Dictionary.getMatchlistResultText(winner, outcome);
            //var url = URLEditor.getGameLink(match[0]);
            var id = Std.parseInt(match[0]);

            scrollview.addComponent(haxeuiLink(text, id));
        }

        vbox.addComponent(scrollview);

        vbox.x = 30;
        vbox.y = 100;
        addChild(vbox);

        var returnBtn = new Button();
		returnBtn.width = 100;
		returnBtn.text = Dictionary.getPhrase(RETURN);
		returnBtn.onClick = (e) -> {ScreenManager.instance.toMain();};
            
        returnBtn.x = 10;
	    returnBtn.y = 10;
	    addChild(returnBtn);
    }

    //! Not guaranteed to work (reasons: SpriteComponent, color/underline, forces reload)
    private function openflLink(text:String, url:String):Component
    {
        var comp:SpriteComponent = new SpriteComponent();
        var sprite:Sprite = new Sprite();
        var tf:TextField = new TextField();
        tf.text = text;
        tf.setTextFormat(new TextFormat(null, 12, null, null, null, null, url));
        sprite.addChild(tf);
        comp.sprite = sprite;
        return comp;
    }

    private function haxeuiLink(text:String, gameID:Int):Button
    {
        var btn:Button = new Button();
        btn.text = text;
        btn.onClick = (e) -> {Networker.getGame(gameID, (d)->{}, (d)->{}, ScreenManager.instance.toRevisit.bind(gameID), ()->{});};
        btn.width = 500;
        btn.horizontalAlign = 'center';
        return btn;
    }
}
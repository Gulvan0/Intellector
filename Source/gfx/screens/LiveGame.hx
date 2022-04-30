package gfx.screens;

import gfx.game.GameLayout;
import net.GeneralObserver;
import openfl.Assets;
import struct.ActualizationData;
import struct.PieceColor;
import utils.TimeControl;

class LiveGame extends Screen
{
    private var gameLayout:GameLayout;

    public override function onEntered()
    {
        GeneralObserver.acceptsDirectChallenges = false;
        Networker.eventQueue.addObserver(gameLayout);
		Assets.getSound("sounds/notify.mp3").play();
    }

    public override function onClosed()
    {
        Networker.eventQueue.removeObserser(gameLayout);
        GeneralObserver.acceptsDirectChallenges = true;
    }

    public static function constructFromActualizationData(actualizationData:ActualizationData, ?orientationColor:PieceColor):LiveGame
    {
        var playerColor:Null<PieceColor> = actualizationData.logParserOutput.getPlayerColor();

        if (orientationColor == null)
            if (playerColor == null)
                orientationColor = White;
            else
                orientationColor = playerColor;

        var gameLayout:GameLayout = GameLayout.constructFromActualizationData(actualizationData, playerColor, orientationColor);
        return new LiveGame(gameLayout);
    }

    public static function constructFromParams(whiteLogin:String, blackLogin:String, orientationColor:PieceColor, timeControl:TimeControl, playerColor:Null<PieceColor>):LiveGame 
    {
        var gameLayout:GameLayout = GameLayout.constructFromParams(whiteLogin, blackLogin, orientationColor, timeControl, playerColor);
        return new LiveGame(gameLayout);
    }

    private function new(gameLayout:GameLayout)
    {
        super();
        this.gameLayout = gameLayout;

        content.addComponent(gameLayout);
    }
}
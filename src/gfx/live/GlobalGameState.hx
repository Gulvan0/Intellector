package gfx.live;

import gfx.live.struct.GlobalStateInitializer;
import gfx.live.interfaces.IReadOnlyMsRemainders;
import gfx.live.struct.ConstantGameParameters;
import gfx.live.struct.MsRemaindersData;
import serialization.GameLogParser.GameLogParserOutput;
import utils.TimeControl;
import net.shared.utils.PlayerRef;
import struct.Variant;
import net.shared.PieceColor;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.RawPly;
import gfx.live.interfaces.IReadOnlyGlobalState;
import gfx.live.interfaces.IReadOnlyHistory;
import net.shared.board.Situation;

class GlobalGameState implements IReadOnlyGlobalState
{
    public var constantParams:ConstantGameParameters;

    public var orientation:PieceColor;
    public var shownSituation:Situation;
    public var currentSituation:Situation;
    public var history:History;
    public var shownMove:Int;
    public var plannedPremoves:Array<RawPly>;
    public var offerActive:Map<OfferKind, Map<OfferDirection, Bool>>;
    public var timeData:TimeReservesData;
    public var perMoveTimeRemaindersData:MsRemaindersData;
    public var activeTimerColor:PieceColor;
    public var boardInteractivityMode:InteractivityMode;
    public var chatHistory:Array<ChatEntry>;
    public var studyVariant:Variant;
    public var playerOnline:Map<PieceColor, Bool>;
    public var spectatorRefs:Array<PlayerRef>;

    public function getConstantParams():ConstantGameParameters
    {
        return constantParams;
    }

    public function getOrientation():PieceColor
    {
        return orientation;
    }

    public function getShownSituation():Situation
    {
        return shownSituation.copy();
    }

    public function getCurrentSituation():Situation
    {
        return currentSituation.copy();
    }

    public function getHistory():IReadOnlyHistory
    {
        return history;
    }

    public function getShownMove():Int
    {
        return shownMove;
    }

    public function getPlannedPremoves():Array<RawPly>
    {
        return plannedPremoves.map(p -> p.copy());
    }

    public function isOfferActive(kind:OfferKind, direction:OfferDirection):Bool
    {
        return offerActive.get(kind).get(direction);
    }

    public function getTimeData():TimeReservesData
    {
        return timeData.copy();
    }

    public function getPerMoveTimeRemainderData():IReadOnlyMsRemainders
    {
        return perMoveTimeRemaindersData;
    }

    public function getActiveTimerColor():PieceColor 
    {
        return activeTimerColor;    
    }

    public function getBoardInteractivityMode():InteractivityMode
    {
        return boardInteractivityMode;
    }

    public function getChatHistory():Array<ChatEntry> 
    {
        return chatHistory.copy();
    }

    public function getStudyVariant():Variant 
    {
        return studyVariant;
    }

    public function isPlayerOnline(color:PieceColor):Bool 
    {
        return playerOnline.get(color);
    }

    public function getSpectatorRefs():Array<PlayerRef> 
    {
        return spectatorRefs.copy();
    }

    private function processCommonParsedData(parsedData:GameLogParserOutput) 
    {
        //TODO: Fill
    }

    public function new(initializer:GlobalStateInitializer) 
    {
        switch initializer 
        {
            case New(parsedData):
                processCommonParsedData(parsedData);
                //TODO: Fill
            case Ongoing(parsedData, timeData, followedPlayerLogin):
                processCommonParsedData(parsedData);
                //TODO: Fill
            case Past(parsedData, watchedPlyerLogin):
                processCommonParsedData(parsedData);
                //TODO: Fill
            case Analysis(initialVariant, selectedBranch, shownMoveNum):
                //TODO: Fill
        }
    }
}
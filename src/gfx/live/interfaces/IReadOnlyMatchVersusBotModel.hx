package gfx.live.interfaces;

interface IReadOnlyMatchVersusBotModel 
{
    public function getGameID():Int;
    public function getOpponentBot():Bot;
    public function getTimeControl():TimeControl;
    public function getPlayerRef(color:PieceColor):PlayerRef;
    public function hasEnded():Bool;
    public function getOutcome():Outcome;
    public function getDateTime():Date;
    public function getStartingSituation():Situation;
    public function getOrientation():PieceColor;
    public function getShownSituation():Situation;
    public function getCurrentSituation():Situation;
    public function getHistory():IReadOnlyHistory;
    public function getShownMove():Int;
    public function getPlannedPremoves():Array<RawPly>;
    public function getTimeReservesData():TimeReservesData;
    public function getMsRemainders():IReadOnlyMsRemainders;
    public function getActiveTimerColor():PieceColor;
    public function getBoardInteractivityMode():InteractivityMode;
    public function getChatHistory():PieceColor;
    public function getSpectators():Array<PlayerRef>;

}
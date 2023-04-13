package gfx.live.interfaces;

interface IReadOnlyMatchVersusPlayerModel 
{
    public function getGameID():Int;
    public function getTimeControl():TimeControl;
    public function getPlayerRef(color:PieceColor):PlayerRef;
    public function isRated():Bool;
    public function getELO(color:PieceColor):EloValue;
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
    public function isOfferActive(kind:OfferKind, direction:OfferDirection):Bool;
    public function getTimeReservesData():TimeReservesData;
    public function getMsRemainders():IReadOnlyMsRemainders;
    public function getActiveTimerColor():PieceColor;
    public function getBoardInteractivityMode():InteractivityMode;
    public function getChatHistory():PieceColor;
    public function isOpponentOnline():Bool;
    public function getSpectators():Array<PlayerRef>;

}
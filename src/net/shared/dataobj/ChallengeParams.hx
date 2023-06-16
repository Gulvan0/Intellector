package net.shared.dataobj;

import net.shared.utils.MathUtils;
import net.shared.board.Situation;

class ChallengeParams
{
    public var type:ChallengeType;
    public var timeControl:TimeControl;
    public var acceptorColor:Null<PieceColor>;
    public var customStartingSituation(default, set):Null<Situation>;
    public var rated(default, set):Bool;

    private function set_customStartingSituation(value:Null<Situation>):Null<Situation>
    {
        if (customStartingSituation != null)
            rated = false;
        return customStartingSituation = value;
    }

    private function set_rated(value:Bool):Bool
    {
        if (value == true)
            customStartingSituation = null;
        return rated = value;
    }

    public static function directChallengeParams(paramsFromCookies:ChallengeParams, calleeRef:String):ChallengeParams
    {
        var params:ChallengeParams = paramsFromCookies;
        params.type = Direct(calleeRef);
        return params;
    }

    public static function anacondaChallengeParams(paramsFromCookies:ChallengeParams):ChallengeParams
    {
        var params:ChallengeParams = paramsFromCookies;
        params.type = Direct("+stconda"); 
        return params;
    }

    public static function botRematchParams(botHandle:String, playerColor:PieceColor, timeControl:TimeControl, rated:Bool, ?startingSituation:Null<Situation>):ChallengeParams
    {
        return new ChallengeParams(timeControl, Direct('+$botHandle'), playerColor, startingSituation, rated);
    }

    public static function rematchParams(opponentLogin:String, playerColor:PieceColor, timeControl:TimeControl, rated:Bool, ?startingSituation:Null<Situation>):ChallengeParams
    {
        return new ChallengeParams(timeControl, Direct(opponentLogin), playerColor, startingSituation, rated);
    }

    public static function playFromPosParams(situiation:Situation):ChallengeParams
    {
        var params:ChallengeParams = defaultParams();
        params.customStartingSituation = situiation;
        return params;
    }

    public static function defaultParams():ChallengeParams
    {
        return new ChallengeParams(TimeControl.normal(10, 0), Public);
    }

    private function isValid():Bool
    {
        return !rated || (customStartingSituation == null && acceptorColor == null);
    }

    public function calculateActualAcceptorColor():PieceColor
    {
        if (acceptorColor != null)
            return acceptorColor;
        else
            return MathUtils.bernoulli(0.5)? White : Black;    
    }

    public function toString():String
    {
        var s = '$type; $timeControl; AcColor: $acceptorColor';
        if (customStartingSituation != null)
            s += '; custom start pos';
        if (rated)
            s += '; rated';
        return s;
    }

    public function new(timeControl:TimeControl, type:ChallengeType, ?acceptorColor:Null<PieceColor>, ?customStartingSituation:Null<Situation>, ?rated:Bool = false)
    {
        this.timeControl = timeControl;
        this.type = type;
        this.acceptorColor = acceptorColor;
        this.customStartingSituation = customStartingSituation;
        this.rated = rated;
    }
}
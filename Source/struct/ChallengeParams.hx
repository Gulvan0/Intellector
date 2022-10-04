package struct;

import net.shared.PieceColor;
import utils.TimeControl;
import js.Cookie;

enum ChallengeType
{
    Public;
    ByLink;
    Direct(calleeLogin:String);
}

class ChallengeParams
{
    private static inline final cookieName:String = "lastChallengeParams";

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

    public function saveToCookies()
    {
        Cookie.set(cookieName, serialize(), 60 * 60 * 24 * 90);
    }

    public static function loadFromCookies():ChallengeParams
    {
        if (Cookie.exists(cookieName))
            return deserialize(Cookie.get(cookieName));
        else
            return defaultParams();
    }

    public static function directChallengeParams(calleeLogin:String):ChallengeParams
    {
        var params:ChallengeParams = loadFromCookies();
        params.type = Direct(calleeLogin);
        return params;
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

    private static function defaultParams():ChallengeParams
    {
        return new ChallengeParams(new TimeControl(600, 0), Public);
    }

    public static function deserialize(s:String):ChallengeParams
    {
        var splitted:Array<String> = s.split(";");
        var timeControl:TimeControl = new TimeControl(Std.parseInt(splitted[0]), Std.parseInt(splitted[1]));
        var type:ChallengeType = splitted[2] == "p"? Public : splitted[2] == "l"? ByLink : Direct(splitted[2]);
        var acceptorColor:Null<PieceColor> = splitted[3] == "w"? White : splitted[3] == "b"? Black : null;
        var customStartingSituation:Null<Situation> = splitted[4] == ""? null : Situation.fromSIP(splitted[4]);
        var rated:Bool = splitted[5] == "t";
        return new ChallengeParams(timeControl, type, acceptorColor, customStartingSituation, rated);
    }

    public function serialize():String
    {
        var typeStr = switch type {
            case Public: "p";
            case ByLink: "l";
            case Direct(calleeLogin): calleeLogin;
        };

        var colorStr = switch acceptorColor {
            case null: "";
            case White: "w";
            case Black: "b";
        }

        var sitStr = customStartingSituation == null? "" : customStartingSituation.serialize();
        var ratedStr = rated? "t" : "";

        return timeControl.startSecs + ";" + timeControl.bonusSecs + ";" + typeStr + ";" + colorStr + ";" + sitStr + ";" + ratedStr;
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
package;

import Figure.FigureType;
import openfl.utils.Assets;
import js.Browser;
import haxe.Json;
import hx.ws.WebSocket;

typedef Event =
{
    var name:String;
    var data:Dynamic;
}

typedef BattleData =
{
    var match_id:Int;
    var enemy:String;
    var colour:String;
    var startSecs:Int;
    var bonusSecs:Int;
}

typedef MoveData =
{
    var issuer_login:String;
    var fromI:Int;
    var toI:Int;
    var fromJ:Int;
    var toJ:Int;
    var morphInto:Null<String>;
}

typedef GameOverData =
{
    var winner_color:String;
    var reason:String;
}

typedef TimeData =
{
    var whiteSeconds:Int;
    var blackSeconds:Int;
}

typedef OpenChallengeData = 
{
    var challenger:String;
    var startSecs:Int;
    var bonusSecs:Int;
}

typedef MessageData =
{
    var issuer_login:String;
    var message:String;
}

class Networker
{

    private static var _ws:WebSocket;
    public static var login:String;

    private static var gameStartHandler:BattleData->Void;
    private static var eventMap:Map<String, Dynamic->Void> = [];

    public static function connect(onGameStated:BattleData->Void, onConnected:Void->Void) 
    {
        #if prod
        _ws = new WebSocket("ws://13.48.10.164:5000");
        #else
        _ws = new WebSocket("ws://localhost:5000");
        #end
        _ws.onopen = function() {
            trace("open");
            gameStartHandler = onGameStated;
            once('game_started', gameStartHandler);
            onConnected();
        };
        _ws.onmessage = function(msg) {
            var str:String = msg.toString();
            var event:Event = Json.parse(str.substring(11, str.length - 1));
            var callback = eventMap.get(event.name);
            if (callback != null)
                callback(event.data);
            else 
                trace("Uncaught event: " + event.name);
        };
        _ws.onclose = function() {
            _ws = null;
        };
        _ws.onerror = function(err) {
            trace("error: " + err.toString());
        }
    }

    public static function signin(login:String, password:String, onAnswer:String->Void) 
    {
        Networker.login = login;
        once('login_result', onAnswer);
        emit('login', {login: login, password: password});
    }

    public static function register(login:String, password:String, onAnswer:String->Void) 
    {
        Networker.login = login;
        once('register_result', onAnswer);
        emit('register', {login: login, password: password});
    }

    public static function getGame(id:Int, onInProcess:(log:String)->Void, onFinished:(log:String)->Void, on404:Void->Void) 
    {
        onceOneOf([
            'gamestate_ongoing' => (data) -> {onInProcess(data.log);},
            'gamestate_over' => (data) -> {onFinished(data.log);},
            'gamestate_notfound' => (data) -> {on404();}
        ]);
        emit('get_game', {id: id});
    }

    public static function getOpenChallenge(challenger:String, onExists:OpenChallengeData->Void, on404:Void->Void) 
    {
        onceOneOf([
            'openchallenge_info' => onExists,
            'openchallenge_notfound' => (data) -> {on404();}
        ]);
        emit('get_challenge', {challenger: challenger});
    }

    public static function acceptOpen(caller:String) 
    {
        if (Networker.login == null)
            Networker.login = "guest_" + Math.ceil(Math.random() * 100000);
        emit('accept_open_challenge', {caller_login: caller, callee_login: Networker.login});
    }

    private static function challengeReceiver(data) 
    {
        var onConfirmed = () -> {emit('accept_challenge', {caller_login: data.caller, callee_login: Networker.login});};
        var onDeclined = () -> {emit('decline_challenge', {caller_login: data.caller, callee_login: Networker.login});};

        Assets.getSound("sounds/social.mp3").play();
        Dialogs.confirm('${data.caller} wants to play with you. Accept the challenge?', "Incoming challenge", onConfirmed, onDeclined);
    }

    public static function sendChallenge(callee:String, secsStart:Int, secsBonus:Int) 
    {
        var onSuccess = (d) -> {
            Assets.getSound("sounds/challenge_sent.mp3").play();
            Dialogs.info('Challenge sent to ${d.callee}!', "Success");
        };
        var onDeclined = (d) -> {Dialogs.info('${d.callee} has declined your challenge', "Challenge declined");};
        var onSame = (d) -> {Dialogs.alert("You can't challenge yourself", "Challenge error");};
        var onRepeated = (d) -> {Dialogs.alert("You have already sent a challenge to this player", "Challenge error");};
        var onOffline = (d) -> {Dialogs.alert("Callee is offline", "Challenge error");};
        var onIngame = (d) -> {Dialogs.alert("Callee is currently playing", "Challenge error");};

        once('challenge_declined', onDeclined);
        onceOneOf(['callee_same' => onSame, 'callout_success' => onSuccess, 'repeated_callout' => onRepeated, 'callee_unavailable' => onOffline, 'callee_ingame' => onIngame]);
        emit('callout', {caller_login: Networker.login, callee_login: callee, secsStart: secsStart, secsBonus: secsBonus});
    }

    public static function sendOpenChallenge(startSecs:Int, bonusSecs:Int) 
    {
        emit('open_callout', {caller_login: Networker.login, startSecs: startSecs, bonusSecs: bonusSecs});
    }

    public static function sendMessage(text:String) 
    {
        emit('message', {issuer_login: Networker.login, message: text});
    }

    public static function reqTimeoutCheck() 
    {
        emit('request_timeout_check', {issuer_login: Networker.login});
    }

    public static function move(fromI:Int, fromJ:Int, toI:Int, toJ:Int, ?morphInto:FigureType) 
    {
        emit('move', {issuer_login: Networker.login, fromI: fromI, fromJ: fromJ, toI: toI, toJ: toJ, morphInto: morphInto == null? null : morphInto.getName()});
    }

    public static function registerGameEvents(onMove:MoveData->Void, onMessage:MessageData->Void, onTimeCorrection:TimeData->Void, onOver:GameOverData->Void) 
    {
        off('incoming_challenge');
        on('move', onMove);
        on('message', onMessage);
        on('time_correction', onTimeCorrection);
        once('game_ended', onOver);
    }

    public static function registerMainMenuEvents()
    {
        off('move');
        off('message');
        off('time_correction');
        on('incoming_challenge', challengeReceiver);
        once('game_started', gameStartHandler);
    }

    public static function dropConnection() 
    {
        _ws.close();
    }

    private static function on(eventName:String, callback:Dynamic->Void) 
    {
        eventMap[eventName] = callback;
    }

    private static function once(eventName:String, callback:Dynamic->Void) 
    {
        eventMap[eventName] = combineSecond(off.bind(eventName), callback);
    }

    private static function onceOneOf(callbacks:Map<String, Dynamic->Void>) 
    {
        var disableAll:Void->Void = () -> {
            for (eventName in callbacks.keys())
                off(eventName);
        };
        
        for (eventName => callback in callbacks.keyValueIterator())
            on(eventName, combineSecond(disableAll, callback));
    }

    private static function off(eventName:String) 
    {
        eventMap.remove(eventName);
    }

    private static function emit(eventName:String, data:Dynamic) 
    {
        var event:Event = {name: eventName, data: data};
        trace("Emitted: " + Json.stringify(event));
        _ws.send(Json.stringify(event));
    }

    public static function combineVoid(f1:Void->Void, f2:Void->Void):Void->Void
    {
        return () -> {f1(); f2();};
    }

    public static function combineFirst<T>(f1:T->Void, f2:Void->Void):T->Void
    {
        return (t:T) -> {f1(t); f2();};
    }

    public static function combineSecond<T>(f1:Void->Void, f2:T->Void):T->Void
    {
        return (t:T) -> {f1(); f2(t);};
    }
}
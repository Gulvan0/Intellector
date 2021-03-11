package;

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
    var enemy:String;
    var colour:String;
}

typedef MoveData =
{
    var issuer_login:String;
    var fromI:Int;
    var toI:Int;
    var fromJ:Int;
    var toJ:Int;
}

typedef GameOverData =
{
    var winner_color:String;
    var reason:String;
}

class Networker
{

    private static var _ws:WebSocket;
    private static var login:String;

    private static var eventMap:Map<String, Dynamic->Void> = [];

    public static function connect() 
    {
        _ws = new WebSocket("ws://localhost:5000");
        _ws.onopen = function() {
            trace("open");
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

    public static function registerChallengeReceiver(onStarted:BattleData->Void) 
    {
        on('incoming_challenge', challengeReceiver.bind(onStarted));
    }

    private static function challengeReceiver(onStarted:BattleData->Void, data) 
    {
        function onConfirmed() 
        {
            emit('accept_challenge', {caller_login: data.caller, callee_login: Networker.login});
            once('game_started', onStarted);
        }

        Dialogs.confirm('${data.caller} wants to play with you. Accept the challenge?', "Incoming challenge", onConfirmed, ()->{});
    }

    public static function sendChallenge(callee:String, onStarted:BattleData->Void) 
    {
        var onRepeated = (d) -> {Browser.alert("You have already sent a challenge to this player");};
        var onOffline = (d) -> {Browser.alert("Callee is offline");};
        var onIngame = (d) -> {Browser.alert("Callee is currently playing");};

        if (eventMap.exists('game_started'))
            onceOneOf(['repeated_callout' => onRepeated, 'callee_unavailable' => onOffline, 'callee_ingame' => onIngame]);
        else
            onceOneOf(['game_started' => onStarted, 'repeated_callout' => onRepeated, 'callee_unavailable' => onOffline, 'callee_ingame' => onIngame]);
        emit('callout', {caller_login: Networker.login, callee_login: callee});
    }

    public static function move(fromI:Int, fromJ:Int, toI:Int, toJ:Int) 
    {
        emit('move', {issuer_login: Networker.login, fromI: fromI, fromJ: fromJ, toI: toI, toJ: toJ});
    }

    public static function registerGameEvents(onMove:MoveData->Void, onOver:GameOverData->Void) 
    {
        off('incoming_challenge');
        on('move', onMove);
        once('game_ended', onOver);
    }

    public static function unregisterGameEvents(onGameStarted:BattleData->Void)
    {
        off('move');
        registerChallengeReceiver(onGameStarted);
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
        trace(Json.stringify(event));
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
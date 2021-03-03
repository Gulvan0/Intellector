package;

import haxe.Json;
import hx.ws.WebSocket;

typedef Event =
{
    var name:String;
    var data:Dynamic;
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
        _ws.onmessage = function(msg:Event) {
            var callback = eventMap.get(msg.name);
            if (callback != null)
                callback(msg.data);
            else 
                trace("Uncaught event: " + msg.name);
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

    private static function on(eventName:String, callback:Dynamic->Void) 
    {
        eventMap[eventName] = callback;
    }

    private static function once(eventName:String, callback:Dynamic->Void) 
    {
        eventMap[eventName] = combineSecond(off.bind(eventName), callback);
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
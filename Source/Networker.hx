package;

import url.Utils;
import dict.Dictionary;
import struct.PieceType;
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

typedef OngoingBattleData =
{
    var match_id:Int;
    var requestedColor:String;
    var whiteLogin:String;
    var blackLogin:String;
    var startSecs:Int;
    var bonusSecs:Int;
    var whiteSeconds:Int;
    var blackSeconds:Int;
    var position:String;
    var currentLog:String;
}

class Networker
{

    private static var _ws:WebSocket;
    public static var login:String;

    private static var eventMap:Map<String, Dynamic->Void> = [];

    public static var suppressAlert:Bool;
    public static var doNotReconnect:Bool = false;

    /**The one to receive all game-related events**/
    public static var currentGameCompound:Null<GameCompound>;

    public static function connect(onConnected:Void->Void) 
    {
        #if prod
        _ws = new WebSocket("wss://play-intellector.ru:5000");
        #else
        _ws = new WebSocket("ws://localhost:5000");
        #end
        _ws.onopen = function() {
            suppressAlert = false;
            on("dont_reconnect", onReconnectionForbidden);
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
            ScreenManager.instance.toEmpty();
            if (suppressAlert)
                trace("Connection closed");
            else
            {
                Dialogs.alert(Dictionary.getPhrase(CONNECTION_LOST_ERROR), "Alert");
                suppressAlert = true;
            }
            if (!doNotReconnect)
                connect(onConnected);
        };
        _ws.onerror = function(err:js.html.Event) {
            if (suppressAlert)
                trace("Connection abrupted");
            else
            {
                Dialogs.alert(Dictionary.getPhrase(CONNECTION_ERROR_OCCURED) + err.type, "Error");
                suppressAlert = true;
            }
        }
    }

    private static function onReconnectionForbidden(e) 
    {
        doNotReconnect = true;
        Dialogs.alert("Session closed", "Alert");
    }

    public static function signin(login:String, password:String, onPlainAnswer:String->Void, onOngoingGame:OngoingBattleData->Void) 
    {
        Networker.login = login;
        onceOneOf([
            'login_result' => onPlainAnswer,
            'ongoing_game' => onOngoingGame
        ]);
        emit('login', {login: login, password: password});
    }

    public static function register(login:String, password:String, onAnswer:String->Void) 
    {
        Networker.login = login;
        once('register_result', onAnswer);
        emit('register', {login: login, password: password});
    }

    public static function getGame(id:Int, onInProcess:OngoingBattleData->Void, onFinished:(log:String)->Void, on404:Void->Void) 
    {
        onceOneOf([
            'ongoing_game' => onInProcess,
            'gamestate_over' => (data) -> {onFinished(data.log);},
            'gamestate_notfound' => (data) -> {on404();}
        ]);
        emit('get_game', {id: id});
    }

    public static function getOpenChallenge(challenger:String, onExists:OpenChallengeData->Void, onInProcess:OngoingBattleData->Void, on404:Void->Void) 
    {
        onceOneOf([
            'openchallenge_info' => onExists,
            'openchallenge_ongoing' => onInProcess,
            'openchallenge_notfound' => (data) -> {on404();}
        ]);
        emit('get_challenge', {challenger: challenger});
    }

    public static function acceptOpen(caller:String) 
    {
        if (Networker.login == null)
            Networker.login = "guest_" + Math.ceil(Math.random() * 100000);
        once("one_time_login_details", (data) ->
        {
            Utils.saveLoginDetails(login, data.password);
        });
        emit('accept_open_challenge', {caller_login: caller, callee_login: Networker.login});
    }

    public static function spectate(watchedLogin:String, onStarted:OngoingBattleData->Void) 
    {
        onceOneOf([
            'watched_unavailable' => (data) -> {Dialogs.alert(Dictionary.getPhrase(SPECTATION_ERROR_REASON_OFFLINE), Dictionary.getPhrase(SPECTATION_ERROR_TITLE));},
            'watched_notingame' => (data) -> {Dialogs.alert(Dictionary.getPhrase(SPECTATION_ERROR_REASON_NOTINGAME), Dictionary.getPhrase(SPECTATION_ERROR_TITLE));},
            'spectation_data' => (data:OngoingBattleData) -> {
                on('move', currentGameCompound.onMove);
                on('time_correction', currentGameCompound.onTimeCorrection);
                on('draw_offered', onDrawOffered);
                on('takeback_offered', onTakebackOffered);
                onStarted(data);
            }
        ]);
        emit('spectate', {watched_login: watchedLogin});
    }

    public static function stopSpectate() 
    {
        off('move');
        off('time_correction');
        off('draw_offered');
        off('draw_cancelled');
        off('draw_accepted');
        off('draw_declined');
        emit('stop_spectate', {});
    }

    private static function challengeReceiver(data) 
    {
        var onConfirmed = () -> {emit('accept_challenge', {caller_login: data.caller, callee_login: Networker.login});};
        var onDeclined = () -> {emit('decline_challenge', {caller_login: data.caller, callee_login: Networker.login});};

        Assets.getSound("sounds/social.mp3").play();
        Dialogs.confirm('${data.caller}' + Dictionary.getPhrase(INCOMING_CHALLENGE_QUESTION), Dictionary.getPhrase(INCOMING_CHALLENGE_TITLE), onConfirmed, onDeclined);
    }

    public static function sendChallenge(callee:String, secsStart:Int, secsBonus:Int) 
    {
        var onSuccess = (d) -> {
            Assets.getSound("sounds/challenge_sent.mp3").play();
            Dialogs.info(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SUCCESS) + '${d.callee}!', Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SUCCESS_TITLE));
        };
        var onDeclined = (d) -> {Dialogs.info('${d.callee}' + Dictionary.getPhrase(SEND_CHALLENGE_RESULT_DECLINED), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_DECLINED_TITLE));};
        var onSame = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SAME), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};
        var onRepeated = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_REPEATED), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};
        var onOffline = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_OFFLINE), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};
        var onIngame = (d) -> {Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_BUSY), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));};

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

    public static function move(fromI:Int, fromJ:Int, toI:Int, toJ:Int, ?morphInto:PieceType) 
    {
        emit('move', {issuer_login: Networker.login, fromI: fromI, fromJ: fromJ, toI: toI, toJ: toJ, morphInto: morphInto == null? null : morphInto.getName()});
    }

    public static function offerDraw() 
    {
        onceOneOf(['draw_accepted' => onDrawAccepted, 'draw_declined' => onDrawDeclined]);
        emit('draw_offer', {});
    }

    public static function cancelDraw() 
    {
        emit('draw_cancel', {});
        off('draw_accepted');
        off('draw_declined');
    }

    public static function acceptDraw() 
    {
        emit('draw_accept', {});
        off('draw_cancelled');
    }

    public static function declineDraw() 
    {
        emit('draw_decline', {});
        off('draw_cancelled');
    }

    private static function onDrawOffered(e) 
    {
        once('draw_cancelled', onDrawCancelled);
        currentGameCompound.onDrawOffered();
    }

    private static function onDrawCancelled(e) 
    {
        currentGameCompound.onDrawCancelled();
    }

    private static function onDrawAccepted(e) 
    {
        currentGameCompound.onDrawAccepted();
    }

    private static function onDrawDeclined(e) 
    {
        currentGameCompound.onDrawDeclined();
    }

    public static function offerTakeback() 
    {
        onceOneOf(['takeback_accepted' => onTakebackAccepted, 'takeback_declined' => onTakebackDeclined]);
        emit('takeback_offer', {});
    }

    public static function cancelTakeback() 
    {
        emit('takeback_cancel', {});
        off('takeback_accepted');
        off('takeback_declined');
    }

    public static function acceptTakeback() 
    {
        emit('takeback_accept', {});
        off('takeback_cancelled');
    }

    public static function declineTakeback() 
    {
        emit('takeback_decline', {});
        off('takeback_cancelled');
    }

    private static function onTakebackOffered(e) 
    {
        once('takeback_cancelled', onTakebackCancelled);
        currentGameCompound.onTakebackOffered();
    }

    private static function onTakebackCancelled(e) 
    {
        currentGameCompound.onTakebackCancelled();
    }

    private static function onTakebackAccepted(e) 
    {
        currentGameCompound.onTakebackAccepted();
    }

    private static function onTakebackDeclined(e) 
    {
        currentGameCompound.onTakebackDeclined();
    }

    private static function onRollbackCommand(cnt:Int) 
    {
        currentGameCompound.onRollbackCommand(cnt);
    }

    private static function onOpponentDisconnected(e) 
    {
        currentGameCompound.onOpponentDisconnected();
    }

    private static function onOpponentReconnected(e) 
    {
        currentGameCompound.onOpponentReconnected();
    }

    public static function registerGameEvents(onOver:GameOverData->Void) 
    {
        off('incoming_challenge');
        on('move', currentGameCompound.onMove);
        on('message', currentGameCompound.onMessage);
        on('time_correction', currentGameCompound.onTimeCorrection);
        on('new_spectator', currentGameCompound.onSpectatorConnected);
        on('spectator_left', currentGameCompound.onSpectatorDisonnected);
        on('draw_offered', onDrawOffered);
        on('takeback_offered', onTakebackOffered);
        on('rollback', onRollbackCommand);
        on('opponent_disconnected', onOpponentDisconnected);
        on('opponent_reconnected', onOpponentReconnected);
        once('game_ended', onOver);
    }

    public static function registerMainMenuEvents()
    {
        off('move');
        off('message');
        off('time_correction');
        off('new_spectator');
        off('spectator_left');
        off('draw_offered');
        off('draw_cancelled');
        off('draw_accepted');
        off('draw_declined');
        off('takeback_offered');
        off('takeback_cancelled');
        off('takeback_accepted');
        off('takeback_declined');
        off('rollback');
        off('opponent_disconnected');
        off('opponent_reconnected');
        on('incoming_challenge', challengeReceiver);
        once('game_started', ScreenManager.instance.toGameStart);
    }

    public static function dropConnection() 
    {
        if (_ws != null)
        {
            suppressAlert = true;
            _ws.close();
            _ws = null;
        }
    }

    private static function on(eventName:String, callback:Dynamic->Void) 
    {
        eventMap[eventName] = callback;
    }

    public static function once(eventName:String, callback:Dynamic->Void) 
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

    public static function emit(eventName:String, data:Dynamic) 
    {
        var event:Event = {name: eventName, data: data};
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
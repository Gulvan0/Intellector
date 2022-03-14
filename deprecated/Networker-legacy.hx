package;

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
            var event:NetEvent = Json.parse(str.substring(11, str.length - 1));
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
    
    public static function dropConnection() 
    {
        if (_ws != null)
        {
            suppressAlert = true;
            _ws.close();
            _ws = null;
        }
    }

    private static function onReconnectionForbidden(e) 
    {
        doNotReconnect = true;
        Dialogs.alert("Session closed", "Alert");
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

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

    public static function getGames(login:String, after:Int, pageSize:Int, onPlayerExists:String->Void, onPlayerNotFound:Void->Void) 
    {
        onceOneOf([
            'games_list' => onPlayerExists,
            'player_not_found' => e -> {onPlayerNotFound();}
        ]);
        emit('get_player_games', {login: login, after: after, pageSize: pageSize});
    }

    public static function getStudies(login:String, after:Int, pageSize:Int, onPlayerExists:String->Void, onPlayerNotFound:Void->Void) 
    {
        onceOneOf([
            'studies_list' => onPlayerExists,
            'player_not_found' => e -> {onPlayerNotFound();}
        ]);
        emit('get_player_studies', {login: login, after: after, pageSize: pageSize});
    }

    public static function setStudy(name:String, variantStr:String, startingSIP:String, overwriteID:Null<Int>) 
    {
        emit('set_study', {name: name, variantStr: variantStr, startingSIP: startingSIP, overwriteID: overwriteID});
    }

    public static function checkPlayerExistance(login:String, callback:Bool->Void)
    {
        once('player_exists_answer', callback);
        emit('player_exists', {login: login});
    }

    public static function getGame(id:Int, onNotOwnInProcess:OngoingBattleData->Void, onOwnInProcess:OngoingBattleData->Void, onFinished:(log:String)->Void, on404:Void->Void) 
    {
        onceOneOf([
            'gamestate_own_ongoing' => onOwnInProcess,
            'spectation_data' => onNotOwnInProcess,
            'gamestate_over' => (data) -> {onFinished(data.log);},
            'gamestate_notfound' => (data) -> {on404();}
        ]);
        emit('get_game', {id: id});
    }

    public static function getOpenChallenge(challenger:String, onExists:OpenChallengeData->Void, onNotOwnInProcess:OngoingBattleData->Void, onOwnInProcess:OngoingBattleData->Void, on404:Void->Void) 
    {
        onceOneOf([
            'openchallenge_info' => onExists,
            'openchallenge_own_ongoing' => onOwnInProcess,
            'spectation_data' => onNotOwnInProcess,
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
            'spectation_data' => onStarted
        ]);
        emit('spectate', {watched_login: watchedLogin});
    }

    public static function stopSpectation() 
    {
        disableSpectationEvents();
        emit('stop_spectate', {});
    }

    private static function challengeReceiver(data:{caller:String, startSecs:Int, bonusSecs:Int, color:String}) 
    {
        var onConfirmed = () -> {emit('accept_challenge', {caller_login: data.caller, callee_login: Networker.login});};
        var onDeclined = () -> {emit('decline_challenge', {caller_login: data.caller, callee_login: Networker.login});};

        Assets.getSound("sounds/social.mp3").play();
        Dialogs.confirm(Dictionary.getIncomingChallengeText(data), Dictionary.getPhrase(INCOMING_CHALLENGE_TITLE), onConfirmed, onDeclined);
    }

    public static function sendChallenge(callee:String, secsStart:Int, secsBonus:Int, color:Null<PieceColor>) 
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
        emit('callout', {caller_login: Networker.login, callee_login: callee, secsStart: secsStart, secsBonus: secsBonus, color: color == null? null : color.getName()});
    }

    public static function sendOpenChallenge(startSecs:Int, bonusSecs:Int, color:Null<PieceColor>) 
    {
        emit('open_callout', {caller_login: Networker.login, startSecs: startSecs, bonusSecs: bonusSecs, color: color == null? null : color.getName()});
    }

    public static function cancelOpenChallenge() 
    {
        emit('cancel_open_callout', {caller_login: Networker.login});
    }
}
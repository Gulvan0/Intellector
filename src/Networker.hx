package;

import lzstring.LZString;
import js.lib.Uint8Array;
import net.shared.ServerMessage;
import net.shared.ClientMessage;
import net.IncomingEventBuffer;
import utils.StringUtils;
import gfx.popups.ReconnectionDialog;
import browser.Url;
import js.html.XMLHttpRequest;
import haxe.Http;
import js.Browser;
import serialization.GameLogParser;
import gfx.ScreenNavigator;
import browser.CredentialCookies;
import net.shared.dataobj.GreetingResponseData;
import net.Requests;
import hx.ws.Types.MessageType;
import haxe.Unserializer;
import haxe.Serializer;
import js.html.Event;
import net.shared.ClientEvent;
import net.shared.ServerEvent;
import net.shared.dataobj.SessionRestorationResult;
import net.EventProcessingQueue;
import gfx.Dialogs;
import gfx.SceneManager;
import hx.ws.WebSocket;
import haxe.Timer;

using utils.CallbackTools;
using Lambda;
using hx.strings.Strings;

class Networker
{
    private static var _ws:WebSocket;
    private static var address:String;

    private static var eventQueue:EventProcessingQueue = new EventProcessingQueue();
    private static var incomingBuffer:IncomingEventBuffer;
    private static var sentEvents:Map<Int, ClientEvent>;
    private static var lastSentMessageID:Int;

    private static var suppressAlert:Bool;
    private static var backoffDelay:Float;
    private static var doNotReconnect:Bool = false;
    private static var reconnectionToken:String = "not_set";
    private static var sid:Int = -1;
    private static var isConnected:Bool = false;
    public static var ignoreEmitCalls:Bool = false; 

    private static var serverHeartbeatTimeoutTimer:Timer;
    private static var clientHeartbeatTimer:Timer;
    private static var clientHeartbeatIntervalMs:Int;
    private static var serverHeartbeatTimeoutMs:Int;

    public static function getSessionID():Int
    {
        return sid;
    }

    public static function isConnectedToServer():Bool
    {
        return isConnected;
    }

    private static function createWS()
    {
        _ws = new WebSocket(address, false);
    }

    public static function launch() 
    {
        Serializer.USE_ENUM_INDEX = true;

        if (Config.dict.getBool("secure"))
            address = "wss://";
        else
            address = "ws://";

        address += Config.dict.getString("host") + ":" + Config.dict.getString("port");

        clientHeartbeatIntervalMs = Config.dict.getInt("keep-alive-beat-interval-ms");

        if (clientHeartbeatIntervalMs == null || clientHeartbeatIntervalMs <= 0)
            clientHeartbeatIntervalMs = 5000;

        serverHeartbeatTimeoutMs = Config.dict.getInt("keep-alive-timeout-ms");

        if (serverHeartbeatTimeoutMs == null || serverHeartbeatTimeoutMs <= 0)
            serverHeartbeatTimeoutMs = 10000;

        incomingBuffer = new IncomingEventBuffer(eventQueue.processEvent, requestResend);
        sentEvents = [];
        lastSentMessageID = 0;

        createWS();
        
        _ws.onopen = onConnectionOpen.bind(true);
        _ws.onerror = onErrorBeforeOpen;

        _ws.open();
    }

    private static function onErrorBeforeOpen(e)
    {
        ScreenNavigator.toAnalysis();
        Dialogs.info(SERVER_UNAVAILABLE_DIALOG_TEXT, SERVER_UNAVAILABLE_DIALOG_TITLE);
        startReconnectionAttempts(onConnectionOpen.bind(false));
    }
    
    public static function dropConnection() 
    {
        if (_ws != null)
        {
            suppressAlert = true;
            isConnected = false;

            _ws.close();
            _ws = null;

            onConnectionClosed();
        }
    }

    @:access(hx.ws.WebSocket._ws)
    private static function onConnectionOpen(?navigateByURL:Bool = true)
    {
        if (isConnected)
            return;

        suppressAlert = false;
        isConnected = true;

        _ws.onmessage = onMessageRecieved;
        _ws.onclose = onConnectionClosed;
        _ws.onerror = onConnectionError;

        if (_ws._ws.readyState == 1)
            if (CredentialCookies.hasLoginDetails())
                Requests.greet(Login(CredentialCookies.getLogin(), CredentialCookies.getPassword()), onGreetingAnswered.bind(_, !navigateByURL));
            else
                Requests.greet(Simple, onGreetingAnswered.bind(_, !navigateByURL));
        else
            Timer.delay(() -> {
                if (CredentialCookies.hasLoginDetails())
                    Requests.greet(Login(CredentialCookies.getLogin(), CredentialCookies.getPassword()), onGreetingAnswered.bind(_, !navigateByURL));
                else
                    Requests.greet(Simple, onGreetingAnswered.bind(_, !navigateByURL));
            }, 100);
    }

    private static function onMessageRecieved(msg:MessageType)
    {
        var message:ServerMessage;

        switch msg 
        {
            case BytesMessage(content):
                var lz = new LZString();
                var bytesData = content.readAllAvailableBytes().getData();
                var array = new Uint8Array(bytesData);
                var s:String = lz.decompressFromUint8Array(array);
                onMessageRecieved(StrMessage(s));
                return;
            case StrMessage(content):
                try
                {
                    message = Unserializer.run(content);
                }
                catch (e)
                {
                    trace("Failed to deserialize message: " + content);
                    trace(e);
                    return;
                }
        }

        switch message.event
        {
            case DontReconnect:
                doNotReconnect = true;
                suppressAlert = true;
                Dialogs.alert(SESSION_CLOSED_ALERT_TEXT, SESSION_CLOSED_ALERT_TITLE);
            case KeepAliveBeat:
                if (serverHeartbeatTimeoutTimer != null)
                    serverHeartbeatTimeoutTimer.stop();
                serverHeartbeatTimeoutTimer = Timer.delay(dropConnection, serverHeartbeatTimeoutMs);
            case ServerError(message):
                Dialogs.alert(SERVER_ERROR_DIALOG_TITLE, SERVER_ERROR_DIALOG_TEXT(StringUtils.shorten(message, 500)));
            case ResendRequest(from, to):
                var map:Map<Int, ClientEvent> = [];
                for (i in from...(to+1))
                    if (sentEvents.exists(i))
                        map.set(i, sentEvents.get(i));
                emitEvent(MissedEvents(map));
            case MissedEvents(map):
                incomingBuffer.pushMissed(map);
                if (!incomingBuffer.isWaiting())
                    Dialogs.getQueue().closeGroup(ReconnectionPopUp);
            default:
                incomingBuffer.push(message);
        }
    }

    private static function onConnectionClosed()
    {
        isConnected = false;

        if (serverHeartbeatTimeoutTimer != null)
            serverHeartbeatTimeoutTimer.stop();
        serverHeartbeatTimeoutTimer = null;

        if (clientHeartbeatTimer != null)
            clientHeartbeatTimer.stop();
        clientHeartbeatTimer = null;

        if (doNotReconnect)
        {
            SceneManager.clearScreen();

            if (!suppressAlert)
            {
                Dialogs.alert(CONNECTION_LOST_ERROR, CONNECTION_ERROR_DIALOG_TITLE);
                suppressAlert = true;
            }
            else
                trace("Connection closed");
        }
        else
        {
            SceneManager.onDisconnected();
            if (!Dialogs.getQueue().hasActiveDialog(ReconnectionPopUp))
                Dialogs.getQueue().add(new ReconnectionDialog());
            startReconnectionAttempts(onConnectionReopened);
        }
    }

    private static function onConnectionError(err:Event)
    {
        isConnected = false;
        trace("Connection error: " + err.type);
    }

    private static function onConnectionReopened()
    {
        isConnected = true;

        _ws.onmessage = onMessageRecieved;
        _ws.onclose = onConnectionClosed;
        _ws.onerror = onConnectionError;

        suppressAlert = false;
        Requests.greet(Reconnect(reconnectionToken, incomingBuffer.lastProcessedEventID), onGreetingAnswered.bind(_, true));
    }

	private static function onGreetingAnswered(data:GreetingResponseData, ?dontLeave:Bool = false)
	{
		switch data 
		{
			case ConnectedAsGuest(sessionID, token, invalidCredentials, isShuttingDown):
                SceneManager.onConnected();
                reconnectionToken = token;
                sid = sessionID;
                if (invalidCredentials)
                    CredentialCookies.removeLoginDetails();
                if (!dontLeave)
                    ScreenNavigator.navigate();
                if (isShuttingDown)
                    Dialogs.alert(SERVER_IS_SHUTTING_DOWN_WARNING_TEXT, SERVER_IS_SHUTTING_DOWN_WARNING_TITLE);
			case Logged(sessionID, token, incomingChallenges, ongoingFiniteGame, isShuttingDown):
                SceneManager.onConnected();
                reconnectionToken = token;
                sid = sessionID;
                LoginManager.assignCredentials(CredentialCookies.getLogin(), CredentialCookies.getPassword(), None);
                GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                if (ongoingFiniteGame != null)
                {
                    var parsedData:GameLogParserOutput = GameLogParser.parse(ongoingFiniteGame.currentLog);
                    SceneManager.toScreen(LiveGame(ongoingFiniteGame.id, Ongoing(parsedData, ongoingFiniteGame.timeData, null)));
                }
                else
                {
                    if (!dontLeave)
                        ScreenNavigator.navigate();
                    if (isShuttingDown)
                        Dialogs.alert(SERVER_IS_SHUTTING_DOWN_WARNING_TEXT, SERVER_IS_SHUTTING_DOWN_WARNING_TITLE); 
                }
			case Reconnected(missedEvents):
                Dialogs.getQueue().closeGroup(ReconnectionPopUp);
                SceneManager.onConnected();
                incomingBuffer.pushMissed(missedEvents);
            case OutdatedClient:
                if (Url.isFallback())
                    Browser.window.location.replace(Url.toActual());
                else
                    Dialogs.alert(OUTDATED_CLIENT_ERROR_TEXT, OUTDATED_CLIENT_ERROR_TITLE); 
            case OutdatedServer:
                if (!Url.isFallback())
                    Browser.window.location.replace(Url.toFallback());
                else
                    Dialogs.alert(OUTDATED_SERVER_ERROR_TEXT, OUTDATED_SERVER_ERROR_TITLE);
            case NotReconnected:
                Browser.location.reload(false);
		}

        if (data.match(ConnectedAsGuest(_, _, _, _) | Logged(_, _, _, _, _) | Reconnected(_)))
        {
            if (serverHeartbeatTimeoutTimer != null)
                serverHeartbeatTimeoutTimer.stop();
            serverHeartbeatTimeoutTimer = Timer.delay(dropConnection, serverHeartbeatTimeoutMs);

            if (clientHeartbeatTimer != null)
                clientHeartbeatTimer.stop();
            clientHeartbeatTimer = new Timer(clientHeartbeatIntervalMs);
            clientHeartbeatTimer.run = emitEvent.bind(KeepAliveBeat);
        }
    }
    
    private static function retryConnecting(onOpen:Void->Void)
    {
        if (_ws != null)
            _ws.close();
        isConnected = false;

        createWS();

        _ws.onopen = onOpen;
        _ws.onerror = e -> {retryConnecting(onOpen);};

        Timer.delay(_ws.open, Math.round(backoffDelay));

        if (backoffDelay < 16000)
            backoffDelay += backoffDelay * (Math.random() - 0.5);
        else
            backoffDelay += 1000 * (Math.random() - 0.5);
    }

    public static function startReconnectionAttempts(onOpen:Void->Void)
    {
        backoffDelay = 1000;
        retryConnecting(onOpen);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    public static function addHandler(handler:ServerEvent->Bool)
    {
        eventQueue.addHandler(handler);
    }

    public static function removeHandler(handler:ServerEvent->Bool)
    {
        eventQueue.removeHandler(handler);
    }

    public static function removeObserver(observer:INetObserver)
    {
        eventQueue.removeObserver(observer);
    }

    public static function addObserver(observer:INetObserver)
    {
        eventQueue.addObserver(observer);
    }

    //=======================================================================================================================

    public static function emitEvent(event:ClientEvent)
    {
        if (ignoreEmitCalls)
            trace(event.getName(), event.getParameters());
        else if (_ws != null)
        {
            var messageID:Int = -1;

            switch event 
            {
                case Greet(_, _, _), KeepAliveBeat, ResendRequest(_, _), MissedEvents(_):
                default:
                    messageID = lastSentMessageID + 1;
                    lastSentMessageID = messageID;
                    sentEvents.set(messageID, event);
            }

            _ws.send(Serializer.run(new ClientMessage(messageID, event)));
        }
    }

    private static function requestResend(from:Int, to:Int) 
    {
        if (from > to)
            return;

        if (!Dialogs.getQueue().hasActiveDialog(ReconnectionPopUp))
            Dialogs.getQueue().add(new ReconnectionDialog());

        emitEvent(ResendRequest(from, to));
    }
}
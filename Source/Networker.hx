package;

import js.html.XMLHttpRequest;
import haxe.Http;
import js.Browser;
import serialization.GameLogParser;
import gfx.ScreenNavigator;
import browser.CredentialCookies;
import net.shared.GreetingResponseData;
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
using StringTools;
using Lambda;

class Networker
{
    private static var _ws:WebSocket;
    private static var address:String;

    public static var eventQueue:EventProcessingQueue = new EventProcessingQueue();

    private static var suppressAlert:Bool;
    private static var backoffDelay:Float;
    private static var doNotReconnect:Bool = false;
    private static var reconnectionToken:String = "not_set";
    private static var isConnected:Bool = false;
    public static var ignoreEmitCalls:Bool = false; 

    public static function getSessionID():String
    {
        return reconnectionToken.split('_')[1];
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
        var event:ServerEvent;

        switch msg 
        {
            case BytesMessage(content):
                trace("Unexpected bytes: " + content.readAllAvailableBytes().toString());
                return;
            case StrMessage(content):
                try
                {
                    event = Unserializer.run(content);
                }
                catch (e)
                {
                    trace("Failed to deserialize message: " + content);
                    trace(e);
                    return;
                }
        }

        switch event
        {
            case DontReconnect:
                doNotReconnect = true;
                suppressAlert = true;
                Dialogs.alert(SESSION_CLOSED_ALERT_TEXT, SESSION_CLOSED_ALERT_TITLE);
            case ServerError(message):
                Dialogs.alert(SESSION_CLOSED_ALERT_TEXT, SESSION_CLOSED_ALERT_TITLE);
            default:
                eventQueue.processEvent(event);
        }
    }

    private static function onConnectionClosed()
    {
        isConnected = false;

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
            Dialogs.reconnectionDialog();
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
        Requests.greet(Reconnect(reconnectionToken), onGreetingAnswered.bind(_, true));
    }

	private static function onGreetingAnswered(data:GreetingResponseData, ?dontLeave:Bool = false)
	{
		switch data 
		{
			case ConnectedAsGuest(token, invalidCredentials):
                SceneManager.onConnected();
                reconnectionToken = token;
                if (invalidCredentials)
                    CredentialCookies.removeLoginDetails();
                if (!dontLeave)
				    ScreenNavigator.navigate();
			case Logged(token, incomingChallenges, ongoingFiniteGame):
                SceneManager.onConnected();
                reconnectionToken = token;
                LoginManager.assignCredentials(CredentialCookies.getLogin(), CredentialCookies.getPassword(), None);
                GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                if (ongoingFiniteGame != null)
                {
                    var parsedData:GameLogParserOutput = GameLogParser.parse(ongoingFiniteGame.currentLog);
                    SceneManager.toScreen(LiveGame(ongoingFiniteGame.id, Ongoing(parsedData, ongoingFiniteGame.timeData, null)));
                }
                else if (!dontLeave)
				    ScreenNavigator.navigate();
			case Reconnected(missedEvents):
                Dialogs.closeReconnectionDialog();
                SceneManager.onConnected();
                for (missedEvent in missedEvents)
                    eventQueue.processEvent(missedEvent);
            case NotReconnected:
                Browser.location.reload(false);
		}
    }
    
    private static function retryConnecting(onOpen:Void->Void)
    {
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
        else
            _ws.send(Serializer.run(event));
    }
}
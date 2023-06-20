package;

import net.shared.dataobj.Greeting;
import net.shared.message.ClientMessage;
import net.shared.message.ClientRequest;
import net.INetObserver;
import lzstring.LZString;
import js.lib.Uint8Array;
import utils.StringUtils;
import gfx.popups.ReconnectionDialog;
import browser.Url;
import js.html.XMLHttpRequest;
import haxe.Http;
import js.Browser;
import gfx.scene.ScreenNavigator;
import browser.CredentialCookies;
import net.shared.dataobj.GreetingResponseData;
import net.Requests;
import hx.ws.Types.MessageType;
import haxe.Unserializer;
import haxe.Serializer;
import js.html.Event;
import net.shared.dataobj.SessionRestorationResult;
import net.EventProcessingQueue;
import gfx.Dialogs;
import gfx.scene.SceneManager;
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
    private static var sentEvents:Map<Int, ClientEvent>;
    private static var lastSentEventID:Int;
    private static var lastProcessedEventID:Int;

    private static var suppressAlert:Bool;
    private static var backoffDelay:Float;
    private static var reconnectionToken:String = "not_set";
    private static var sid:Int = -1;
    private static var isConnected:Bool = false;

    public static var ignoreEmitCalls:Bool = false;
    private static var stayOnPageOnGreetingResponse:Bool = false;

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

        sentEvents = [];
        lastSentEventID = 0;
        lastProcessedEventID = 0;

        Requests.init(sendRequest);
        MessageProcessor.init(eventQueue, _);

        if (Config.dict.getBool("secure"))
            address = "wss://";
        else
            address = "ws://";

        address += Config.dict.getString("host") + ":" + Config.dict.getString("port");

        createWS();
        
        _ws.onopen = onConnectionOpen.bind(true);
        _ws.onerror = onErrorBeforeOpen;

        _ws.open();

        //TODO: Client heartbeat
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

    private static function initialGreeting(stayOnPage:Bool)
    {
        if (CredentialCookies.hasLoginDetails())
            greet(Login(CredentialCookies.getLogin(), CredentialCookies.getPassword()), stayOnPage);
        else
            greet(Simple, stayOnPage);
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
            initialGreeting(!navigateByURL);
        else
            Timer.delay(initialGreeting.bind(!navigateByURL), 100);
    }

    private static function onMessageRecieved(msg:MessageType)
    {
        MessageProcessor.onMessageRecieved(msg);
    }

    private static function onConnectionClosed()
    {
        isConnected = false;
        
        GlobalBroadcaster.broadcast(Disconnected);
        startReconnectionAttempts(onConnectionReopened);
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
        greet(Reconnect(reconnectionToken, lastProcessedEventID), true);
    }

    private static function greet(greeting:Greeting, stayOnPage:Bool)
    {
        stayOnPageOnGreetingResponse = stayOnPage;
        sendMessage(Greet(greeting, Build.buildTime(), Config.dict.getInt("min-server-build")));
    }

    private static function onGreetingAnswered(data:GreetingResponseData)
    {
        switch data 
        {
            case ConnectedAsGuest(sessionID, token, invalidCredentials, isShuttingDown):
                GlobalBroadcaster.broadcast(Connected);
                reconnectionToken = token;
                sid = sessionID;
                if (invalidCredentials)
                    CredentialCookies.removeLoginDetails();
                if (!stayOnPageOnGreetingResponse)
                    ScreenNavigator.navigate();
                if (isShuttingDown)
                    Dialogs.alert(SERVER_IS_SHUTTING_DOWN_WARNING_TEXT, SERVER_IS_SHUTTING_DOWN_WARNING_TITLE);
            case Logged(sessionID, token, incomingChallenges, isShuttingDown):
                GlobalBroadcaster.broadcast(Connected);
                reconnectionToken = token;
                sid = sessionID;
                LoginManager.assignCredentials(CredentialCookies.getLogin(), CredentialCookies.getPassword(), None);
                GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                if (!stayOnPageOnGreetingResponse)
                    ScreenNavigator.navigate();
                if (isShuttingDown)
                    Dialogs.alert(SERVER_IS_SHUTTING_DOWN_WARNING_TEXT, SERVER_IS_SHUTTING_DOWN_WARNING_TITLE);
            case Reconnected(missedEvents, missedRequestResponses, lastReceivedClientEventID):
                GlobalBroadcaster.broadcast(Connected);
                
                var eventTree:BalancedTree<Int, ServerEvent> = new BalancedTree();
                for (id => event in missedEvents.keyValueIterator())
                    eventTree.set(id, event);

                for (id => event in eventTree.keyValueIterator())
                    eventQueue.processEvent(id, event);

                for (id => response in missedRequestResponses.keyValueIterator())
                    Requests.processResponse(id, response);

                //TODO: Undo events if needed
                var lastSentIDBeforeReconnection:Int = lastSentEventID;
                var missedClientEventID:Int = lastReceivedClientEventID + 1;
                while (missedClientEventID <= lastSentIDBeforeReconnection)
                {
                    emitEvent(sentEvents.get(missedClientEventID));
                    missedClientEventID++;
                }

                Requests.repeatUnansweredRequests();
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

        if (backoffDelay < 8000)
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
            lastSentEventID++;
            sentEvents.set(lastSentEventID, event);

            sendMessage(ClientMessage.Event(lastSentEventID, event));
        }
    }

    private static function sendRequest(id:Int, req:ClientRequest)
    {
        sendMessage(ClientMessage.Request(id, req));
    }

    private static function sendMessage(message:ClientMessage)
    {
        _ws.send(Serializer.run(message));
    }
}
package net;

import haxe.ds.BalancedTree;
import net.shared.message.ClientRequest;
import net.shared.message.ServerRequestResponse;
import net.shared.utils.PlayerRef;
import net.shared.dataobj.GameModelData;
import gfx.profile.complex_components.MiniProfile;
import net.shared.utils.Build;
import net.shared.dataobj.GreetingResponseData;
import net.shared.dataobj.Greeting;
import net.shared.dataobj.ChallengeData;
import net.shared.TimeControlType;
import net.shared.dataobj.StudyInfo;
import net.shared.dataobj.ProfileData;
import net.shared.dataobj.ChallengeParams;
import dict.Dictionary;
import gfx.Dialogs;
import gfx.scene.SceneManager;
import net.shared.PieceColor;
import net.shared.TimeControl;

class Requests
{
    private static var pendingRequestHandlers:BalancedTree<Int, ServerRequestResponse->Void> = new BalancedTree();
    private static var sentRequests:Map<Int, ClientRequest> = [];
    private static var lastRequestID:Int = 0;

    private static var requestSender:(id:Int, req:ClientRequest)->Void;

    public static function init(requestSender:(id:Int, req:ClientRequest)->Void)
    {
        Requests.requestSender = requestSender;
    }

    public static function request(request:ClientRequest, handler:ServerRequestResponse->Void)
    {
        lastRequestID++;

        pendingRequestHandlers.set(lastRequestID, handler);
        sentRequests.set(lastRequestID, request);

        requestSender(lastRequestID, request);
    }

    public static function processResponse(requestID:Int, response:ServerRequestResponse)
    {
        if (pendingRequestHandlers.exists(requestID))
            pendingRequestHandlers[requestID](response);

        pendingRequestHandlers.remove(requestID);
    }

    public static function repeatUnansweredRequests()
    {
        var handlers:BalancedTree<Int, ServerRequestResponse->Void> = pendingRequestHandlers.copy();

        pendingRequestHandlers.clear();

        for (requestID => handler in handlers.keyValueIterator())
        {
            var request:ClientRequest = sentRequests[requestID];
            sendRequest(request, handler);
        }
    }

    /* //TODO: Move

    public static function signin(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.addHandler(signin_handler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Login(login, password));
    }

    private static function signin_handler(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case LoginResult(result):
                switch result 
                {
                    case Success(incomingChallenges):
                        LoginManager.assignCredentials(login, password, remember? LongTerm : ShortTerm);
                        GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                        onSuccess();
                    case ReconnectionNeeded(incomingChallenges, data):
                        LoginManager.assignCredentials(login, password, remember? LongTerm : ShortTerm);
                        GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                        SceneManager.getScene().toScreen(GameFromModelData(data, LoginManager.getRef()));
                    case Fail:
                        onFail();
                }
                return true;
            default:
                return false;
        }
    }

    public static function register(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.addHandler(register_handler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Register(login, password));
    }

    private static function register_handler(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case RegisterResult(result):
                if (result == Success)
                {
                    LoginManager.assignCredentials(login, password, remember? LongTerm : ShortTerm);
                    onSuccess();
                }
                else
                    onFail();
                return true;
            default:
                return false;
        }
    }

    public static function getGame(id:Int, ?orientationParticipant:PlayerRef)
    {
        Networker.addHandler(getGame_handler.bind(id, orientationParticipant));
        Networker.emitEvent(GetGame(id));
    }

    private static function getGame_handler(id:Int, orientationParticipant:Null<PlayerRef>, event:ServerEvent):Bool
    {
        switch event
        {
            case GameRetrieved(data):
                SceneManager.getScene().toScreen(GameFromModelData(data, orientationParticipant));
            case GameNotFound:
                SceneManager.getScene().toScreen(MainMenu);
            default:
                return false;
        }
        return true;
    }

    public static function getOpenChallenge(id:Int) 
    {
        Networker.addHandler(getOpenChallenge_handler);
        Networker.emitEvent(GetOpenChallenge(id));
    }

    private static function getOpenChallenge_handler(event:ServerEvent):Bool
    {
        switch event
        {
            case OpenChallengeInfo(data):
                SceneManager.getScene().toScreen(ChallengeJoining(data));
            case OpenChallengeAlreadyAccepted(data):
                SceneManager.getScene().toScreen(GameFromModelData(data));
            case OpenChallengeNotFound:
                SceneManager.getScene().toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_CHALLENGE_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getMiniProfile(login:String) 
    {
        Networker.addHandler(getMiniProfile_handler.bind(login));
        Networker.emitEvent(GetMiniProfile(login));
    }

    private static function getMiniProfile_handler(login:String, event:ServerEvent) 
    {
        switch event
        {
            case MiniProfile(data):
                Dialogs.getQueue().add(new MiniProfile(login, data));
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerProfile(login:String, ?returnToMainOnFailed:Bool = false) 
    {
        Networker.addHandler(getPlayerProfile_handler.bind(login, returnToMainOnFailed));
        Networker.emitEvent(GetPlayerProfile(login));
    }

    private static function getPlayerProfile_handler(login:String, returnToMainOnFailed:Bool, event:ServerEvent) 
    {
        switch event
        {
            case PlayerProfile(data):
                SceneManager.getScene().toScreen(PlayerProfile(login, data));
            case PlayerNotFound:
                if (returnToMainOnFailed)
                    SceneManager.getScene().toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerPastGames(login:String, after:Int, pageSize:Int, filterByTimeControl:Null<TimeControlType>, callback:GetGamesCallback)
    {
        Networker.addHandler(getPlayerGames_handler.bind(callback));
        Networker.emitEvent(GetGamesByLogin(login, after, pageSize, filterByTimeControl));
    }

    public static function getPlayerOngoingGames(login:String, callback:GetGamesCallback)
    {
        Networker.addHandler(getPlayerGames_handler.bind(callback));
        Networker.emitEvent(GetOngoingGamesByLogin(login));
    }

    private static function getPlayerGames_handler(callback:GetGamesCallback, event:ServerEvent) 
    {
        switch event
        {
            case Games(games, hasNext):
                callback(games, hasNext);
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerStudies(login:String, after:Int, pageSize:Int, filterByTags:Null<Array<String>>, callback:GetStudiesCallback)
    {
        Networker.addHandler(getPlayerStudies_handler.bind(callback));
        Networker.emitEvent(GetStudiesByLogin(login, after, pageSize, filterByTags));
    }

    private static function getPlayerStudies_handler(callback:GetStudiesCallback, event:ServerEvent) 
    {
        switch event
        {
            case Studies(studies, hasNext):
                callback(studies, hasNext);
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getStudy(id:Int) 
    {
        Networker.addHandler(getStudy_handler.bind(id));
        Networker.emitEvent(GetStudy(id));
    }

    private static function getStudy_handler(id:Int, event:ServerEvent) 
    {
        switch event
        {
            case SingleStudy(info):
                SceneManager.getScene().toScreen(Study(info));
            case StudyNotFound:
                SceneManager.getScene().toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_STUDY_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function createStudy(params:StudyInfo, onCreated:StudyInfo->Void) 
    {
        Networker.addHandler(createStudy_handler.bind(onCreated));
        Networker.emitEvent(CreateStudy(params));
    }

    private static function createStudy_handler(onCreated:StudyInfo->Void, event:ServerEvent) 
    {
        switch event
        {
            case StudyCreated(info):
                onCreated(info);
            default:
                return false;
        }
        return true;
    }

    public static function followPlayer(login:String, onStartedFollowing:(login:String, activeGameID:Null<Int>)->Void)
    {
        Networker.addHandler(followPlayer_handler.bind(login, onStartedFollowing));
        Networker.emitEvent(FollowPlayer(login));
    }

    private static function followPlayer_handler(login:String, onStartedFollowing:(login:String, activeGameID:Null<Int>)->Void, event:ServerEvent)
    {
        switch event
        {
            case GoToGame(data):
                onStartedFollowing(login, data.gameID);
            case FollowAlreadySpectating(id):
                onStartedFollowing(login, id);
            case FollowSuccess:
                onStartedFollowing(login, null);
                Dialogs.info(REQUESTS_FOLLOW_PLAYER_SUCCESS_DIALOG_TEXT, REQUESTS_FOLLOW_PLAYER_SUCCESS_DIALOG_TITLE);
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getCurrentGames(callback:Array<GameModelData>->Void)
    {
        Networker.addHandler(getCurrentGames_handler.bind(callback));
        Networker.emitEvent(GetCurrentGames);
    }

    private static function getCurrentGames_handler(callback:Array<GameModelData>->Void, event:ServerEvent)
    {
        switch event
        {
            case CurrentGames(data):
                callback(data);
                return true;
            default:
                return false;
        }
    }

    public static function getOpenChallenges(callback:Array<ChallengeData>->Void)
    {
        Networker.addHandler(getOpenChallenges_handler.bind(callback));
        Networker.emitEvent(GetOpenChallenges);
    }

    private static function getOpenChallenges_handler(callback:Array<ChallengeData>->Void, event:ServerEvent)
    {
        switch event
        {
            case OpenChallenges(data):
                callback(data);
                return true;
            default:
                return false;
        }
    }

    public static function getRecentGames(callback:Array<GameModelData>->Void)
    {
        Networker.addHandler(getRecentGames_handler.bind(callback));
        Networker.emitEvent(GetRecentGames);
    }

    private static function getRecentGames_handler(callback:Array<GameModelData>->Void, event:ServerEvent)
    {
        switch event
        {
            case RecentGames(data):
                callback(data);
                return true;
            default:
                return false;
        }
    }*/
}
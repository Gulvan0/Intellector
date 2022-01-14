package net;

import Networker.OngoingBattleData;

class LoginManager
{
    public static var login:String;

    public static function signin(login:String, password:String, onPlainAnswer:String->Void, onOngoingGame:OngoingBattleData->Void) 
    {
        LoginManager.login = login;
        Networker.onceOneOf([
            'login_result' => onPlainAnswer,
            'ongoing_game' => onOngoingGame
        ]);
        Networker.emitEvent('login', {login: login, password: password});
    }

    public static function register(login:String, password:String, onAnswer:String->Void) 
    {
        LoginManager.login = login;
        Networker.once('register_result', onAnswer);
        Networker.emit('register', {login: login, password: password});
    }
}
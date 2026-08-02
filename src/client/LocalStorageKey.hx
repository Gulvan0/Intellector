package client;

enum abstract LocalStorageKey(String) from String to String
{
    var TOKEN:String = "session.token";
    var IDENTITY:String = "session.identity";
    var REMEMBER_ME:String = "session.saved_credentials.remember_me";
    var SAVED_LOGIN:String = "session.saved_credentials.login";
    var SAVED_PASSWORD:String = "session.saved_credentials.password";
}

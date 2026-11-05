package net.rest;

import easyrest.RestClient;
import easyrest.ServerClock;

class Rest
{
    private static inline final REQUEST_TIMEOUT_MS:Int = 10000;

    private static var _client:RestClient;
    private static var _serverClock:ServerClock = new ServerClock("X-Server-Time");

    public static function init(tokenRetriever:()->Null<String>):Void
    {
        _client = new RestClient(Config.BASE_URL);
        _client.timeoutMs = REQUEST_TIMEOUT_MS;
        _client.addCommonHeaderRetriever(() -> {
            var token:Null<String> = tokenRetriever();
            return token != null ? ["intellector-user-token" => token] : [];
        });
        _client.addResponseObserver(_serverClock.observe);
    }

    public static function client():RestClient
    {
        return _client;
    }

    /** The server's clock, estimated from the responses' `X-Server-Time` **/
    public static function serverClock():ServerClock
    {
        return _serverClock;
    }
}

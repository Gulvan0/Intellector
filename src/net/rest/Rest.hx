package net.rest;

import easyrest.RestClient;
import easyrest.ServerClock;

class Rest
{
	private static var _client:RestClient;
	private static var _serverClock:ServerClock = new ServerClock("X-Server-Time");

	public static function init(tokenRetriever:()->Null<String>)
	{
		_client = new RestClient(Config.base_url);
		_client.addCommonHeaderRetriever(()->{
			var token:Null<String> = tokenRetriever();
			return token != null? ["intellector-user-token" => token] : [];
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

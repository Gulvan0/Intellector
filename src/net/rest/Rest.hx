package net.rest;

import easyrest.RestClient;

class Rest
{
	private static var _client:RestClient;

	public static function init(tokenRetriever:()->Null<String>)
	{
		_client = new RestClient(Config.base_url);
		_client.addCommonHeaderRetriever(()->{
			var token:Null<String> = tokenRetriever();
			return token != null? ["intellector-user-token" => token] : [];
		});
	}

	public static function client():RestClient
	{
		return _client;
	}
}

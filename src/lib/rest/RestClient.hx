package lib.rest;

import lib.json.JsonSerializable;
import lib.json.exceptions.UnserializationException;
import lib.rest.exceptions.GetPayloadProvidedException;
import http.HttpMethod;
import http.HttpResponse;
import http.HttpClient;

using lib.std.extensions.MapExtension;
using lib.std.extensions.StringExtension;

private typedef RestOpInterface<Resp> = {
	var path(default, null):String;
	var method(default, null):HttpMethod;
	function deserializeResponse(bodyStr:String):Resp;
}

class RestClient
{
	private var baseUrl:String;
	private var httpClient:HttpClient = new HttpClient();
	private var commonHeaderRetrievers:Array<()->Map<String, String>> = [];

	private function getHeaders(explicitHeaders:Null<Map<String, String>> = null):Map<String, String>
	{
		var headers:Map<String, String> = [];
		for (retriever in commonHeaderRetrievers)
			headers = headers.mergeWith(retriever());
		if (explicitHeaders != null)
			headers = headers.mergeWith(explicitHeaders);
		return headers;
	}

	public function execute<RequestPayloadType:JsonSerializable, ResponsePayloadType>(
		operation:RestOpInterface<ResponsePayloadType>,
		onResponse:ResponsePayloadType->Void,
		onHttpError:HttpResponse<Dynamic>->Void = null,
		pathParams:Map<String, String> = null,
		queryParams:Map<String, Any> = null,
		body:RequestPayloadType = null,
		headers:Map<String, String> = null
	)
	{
		if (operation.method == HttpMethod.Get && body != null)
			throw new GetPayloadProvidedException();

		var url:String = baseUrl + operation.path.pythonicFormat(pathParams ?? []);
		var serializedRequestPayload:String = body != null ? body.serialize() : null;

		httpClient.makeRequest(url, serializedRequestPayload, queryParams, getHeaders(headers)).then(
			response -> {
				try
				{
					var parsedResponse:ResponsePayloadType = operation.deserializeResponse(response.bodyAsString);
					onResponse(parsedResponse);
				}
				catch (exception:UnserializationException)
				{
					trace(exception);
					if (onHttpError != null)
						onHttpError(response);
				}
			},
			error -> {
				onHttpError(error);
			}
		);
	}

	public function addCommonHeaderRetriever(retriever:()->Map<String, String>)
	{
		commonHeaderRetrievers.push(retriever);
	}

	public function removeCommonHeaderRetriever(retriever:()->Map<String, String>)
	{
		commonHeaderRetrievers.remove(retriever);
	}

	public function new(baseUrl:String)
	{
		this.baseUrl = baseUrl;
	}
}

package lib.rest;

import lib.json.JsonUnserializable;
import lib.json.JsonSerializable;
import lib.json.exceptions.UnserializationException;
import lib.rest.exceptions.GetPayloadProvidedException;
import http.HttpMethod;
import http.HttpResponse;
import http.HttpClient;

using lib.std.extensions.MapExtension;
using lib.std.extensions.StringExtension;

class RestClient
{
	private var baseUrl:String;
	private var httpClient:HttpClient = new HttpClient();
	private var commonHeaderRetrievers:Array<()->Map<String, String>> = [];

	private function getHeaders(explicitHeaders:Null<Map<String, String>> = null):Map<String, String>
	{
		var headers:Map<String, String> = [];
		for (retriever in commonHeaderRetrievers)
			headers.mergeWith(retriever());
		if (explicitHeaders != null)
			headers.mergeWith(explicitHeaders);
		return headers;
	}

	@:generic
	public function execute<RequestPayloadType:JsonSerializable, ResponsePayloadType:JsonUnserializable>(
		operation:GenericRestOperation<RequestPayloadType, ResponsePayloadType>,
		onResponse:ResponsePayloadType->Void,
		onHttpError:HttpResponse<Dynamic>->Void = null,
		onRequestPromiseRejected:Dynamic->Void = null,
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
					var parsedResponse:ResponsePayloadType = response.bodyAsString == "null"? null : new ResponsePayloadType(Str(response.bodyAsString));
					onResponse(parsedResponse);
				}
				catch (exception:UnserializationException)
				{
					if (onHttpError != null)
						onHttpError(response);
				}
			},
			rejection -> {
				if (onRequestPromiseRejected != null)
					onRequestPromiseRejected(rejection);
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

package lib.rest;

import http.HttpMethod;
import lib.json.JsonUnserializable;

@:generic
class GetOperaton<ResponsePayloadType:JsonUnserializable> extends GenericRestOperation<NoPayload, ResponsePayloadType>
{
	public function new(path:String)
	{
		super(path, Get);
	}
}

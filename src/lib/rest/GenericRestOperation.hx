package lib.rest;

import lib.json.JsonUnserializable;
import lib.json.JsonSerializable;
import http.HttpMethod;

@:generic
class GenericRestOperation<RequestPayloadType:JsonSerializable, ResponsePayloadType:JsonUnserializable>
{
	public final path:String;
	public final method:HttpMethod;

	public function new(path:String, method:HttpMethod)
	{
		this.path = path;
		this.method = method;
	}
}

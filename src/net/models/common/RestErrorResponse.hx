package net.models.common;

import jsonmodel.IJsonUnserializableMacro;

/** Body of an error response carrying a machine-readable `code`, plus the extra fields some codes come with **/
class RestErrorResponse implements IJsonUnserializableMacro
{
    public var detail:String;
    public var code:RestErrorCode;
    @:default(null) public var challenge_id:Null<Int>;
    @:default(null) public var max_active_challenges:Null<Int>;
}

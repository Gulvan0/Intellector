package lib.rest.exceptions;

import haxe.PosInfos;
import haxe.exceptions.PosException;

class NonUnserializableResponsePayloadClass extends PosException
{
	public function new(classInstance:Class<Dynamic>, ?pos:PosInfos):Void
	{
		super('Response payload class ${Type.getClassName(classInstance)} should be unserializable', null, pos);
	}
}

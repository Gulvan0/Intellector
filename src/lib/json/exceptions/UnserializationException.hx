package lib.json.exceptions;

import json2object.Error;
import haxe.PosInfos;
import haxe.exceptions.PosException;

class UnserializationException extends PosException
{
	public final errors:Array<Error>;

	public function new(errors:Array<Error>, ?pos:PosInfos):Void
	{
		this.errors = errors;
		super('Got errors while parsing payload:\n\n${errors.join("\n")}', null, pos);
	}
}

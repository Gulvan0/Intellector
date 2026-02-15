package lib.rest.exceptions;

import haxe.PosInfos;
import haxe.exceptions.PosException;

class GetPayloadProvidedException extends PosException
{
	public function new(?pos:PosInfos):Void
	{
		super('Get methods should have payload omitted or explicitly set to null', null, pos);
	}
}

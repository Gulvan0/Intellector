package utils.exceptions;

import haxe.PosInfos;
import haxe.Exception;
import haxe.exceptions.PosException;

class AlreadyInitializedException extends PosException 
{
    public function new(message:String = 'Already initialized', ?previous:Exception, ?pos:PosInfos):Void 
    {
		super(message, previous, pos);
	}
}
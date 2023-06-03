package utils.exceptions;

import haxe.PosInfos;
import haxe.Exception;
import haxe.exceptions.PosException;

class WrongModelTypeException extends PosException 
{
    public function new(message:String = 'Wrong model type', ?previous:Exception, ?pos:PosInfos):Void 
    {
        super(message, previous, pos);
    }
}
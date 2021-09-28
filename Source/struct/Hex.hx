package struct;

class Hex 
{
    public var type:Null<PieceType> = null;
    public var color:Null<PieceColor> = null;

    public static function empty():Hex
    {
        return new Hex();
    }

    public static function occupied(type:PieceType, color:PieceColor) :Hex
    {
        var hex = new Hex();
        hex.setPiece(type, color);
        return hex;
    }

    public function equals(hex:Hex):Bool
    {
        return type == hex.type && color == hex.color;
    }

    public function isEmpty():Bool 
    {
        return type == null;    
    }
    
    public function setEmpty() 
    {
        type = null;
        color = null;    
    }

    public function setPiece(type:PieceType, color:PieceColor) 
    {
        this.type = type;
        this.color = color;
    }

    public function copy():Hex
    {
        return isEmpty()? Hex.empty() : Hex.occupied(type, color);
    }

    public function new() 
    {
        
    }
}
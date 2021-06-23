package struct;

@:structInit class HexTransform 
{
    public var coords:IntPoint;
    public var former:Hex;
    public var latter:Hex;

    public function copy():HexTransform
    {
        return new HexTransform(coords, former.copy(), latter.copy());
    }

    public function new(coords, former, latter) 
    {
        this.coords = coords;
        this.former = former;
        this.latter = latter;
    }
}
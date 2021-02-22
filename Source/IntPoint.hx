package;

class IntPoint 
{
    public var i:Int;
    public var j:Int;

    public function equals(p:IntPoint) 
    {
        if (p == null)
            return false;
        return i == p.i && j == p.j;
    }

    public function new(i:Int, j:Int) 
    {
        this.i = i;
        this.j = j;    
    }
}
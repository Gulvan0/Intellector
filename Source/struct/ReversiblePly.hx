package struct;

import struct.HexTransform;

abstract ReversiblePly(Array<HexTransform>) from Array<HexTransform> to Array<HexTransform>
{
    public function equals(rply:Array<HexTransform>)
    {
        var unmatchedTransforms:Array<HexTransform> = this.copy();
        for (ht in rply)
            for (i in 0...unmatchedTransforms.length)
                if (unmatchedTransforms[i].equals(ht))
                {
                    unmatchedTransforms.splice(i, 1);
                    break;
                }
        return Lambda.empty(unmatchedTransforms);
    }

    public function push(ht:HexTransform)
    {
        this.push(ht);
    }

    public function iterator()
    {
        return this.iterator();
    }

    public inline function new(a:Array<HexTransform>) 
    {
        this = a;
    }
}
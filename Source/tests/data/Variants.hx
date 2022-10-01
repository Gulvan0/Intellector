package tests.data;

import struct.Situation;
import struct.Variant;

class Variants
{
    public static function variant1() 
    {
        var sit:Situation = Situation.starting();
        var variant:Variant = new Variant(sit);

        var branch1 = sit.randomContinuation(5);
        var branch2 = sit.randomContinuation(3);

        while (branch1[0].ply.equals(branch2[0].ply))
            branch2 = sit.randomContinuation(3);

        var path:VariantPath = [];
        for (i in 0...5)
        {
            variant.addChildToNode(branch1[i].ply, path);
            path = path.child(0);
        }

        path = [];
        for (i in 0...3)
        {
            variant.addChildToNode(branch2[i].ply, path);
            path = path.child(i == 0? 1 : 0);
        }

        return variant;
    }
}
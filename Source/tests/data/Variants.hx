package tests.data;

import net.shared.board.RawPly;
import net.shared.utils.MathUtils;
import struct.Variant;
import net.shared.board.Situation;

class Variants
{
    public static function variant1() 
    {
        var sit:Situation = Situation.defaultStarting();
        var variant:Variant = new Variant(sit);

        var path:VariantPath = [];
        var firstPly:RawPly = null;

        for (i in 0...5)
        {
            var ply = MathUtils.randomElement(sit.availablePlys());

            if (i == 0)
                firstPly = ply;

            sit.performRawPly(ply);
            variant.addChildToNode(ply, path);
            path = path.child(0);
        }
        
        path = [];
        sit = Situation.defaultStarting();

        for (i in 0...3)
        {
            var ply = MathUtils.randomElement(sit.availablePlys());
            while (ply.equals(firstPly))
                ply = MathUtils.randomElement(sit.availablePlys());

            sit.performRawPly(ply);
            variant.addChildToNode(ply, path);
            path = path.child(i == 0? 1 : 0);
        }

        return variant;
    }
}
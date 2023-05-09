package tests.data;

import net.shared.variation.VariationPath;
import net.shared.variation.Variation;
import net.shared.board.RawPly;
import net.shared.utils.MathUtils;
import net.shared.board.Situation;

class Variations
{
    public static function variation1():Variation 
    {
        var sit:Situation = Situation.defaultStarting();
        var variation:Variation = new Variation(sit);

        var path:VariationPath = [];
        var firstPly:RawPly = null;

        for (i in 0...5)
        {
            var ply = MathUtils.randomElement(sit.availablePlys());

            if (i == 0)
                firstPly = ply;

            sit.performRawPly(ply);
            variation.addChild(path, ply);
            path = path.childPath(0);
        }
        
        path = [];
        sit = Situation.defaultStarting();

        for (i in 0...3)
        {
            var ply = MathUtils.randomElement(sit.availablePlys());
            while (ply.equals(firstPly))
                ply = MathUtils.randomElement(sit.availablePlys());

            sit.performRawPly(ply);
            variation.addChild(path, ply);
            path = path.childPath(i == 0? 1 : 0);
        }

        return variation;
    }
}
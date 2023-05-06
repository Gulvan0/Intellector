package net.shared.variation;

import net.shared.board.Situation;
import net.shared.board.RawPly;

class PlainVariation
{
    private final startingSituation:Situation;
    private final plys:VariationMap<RawPly>;

    public static function fromVariation(variation:ReadOnlyVariation):PlainVariation
    {
        var startingSituation:Situation = variation.rootNode().getSituation();
        var plys:VariationMap<RawPly> = variation.collectNodes(false).map(x -> x.getIncomingPly());
        return new PlainVariation(startingSituation, plys);
    }

    private function addPlyFromMapToVariation(variation:Variation, map:VariationMap<RawPly>, path:VariationPath)
    {
        var parentPath:VariationPath = path.parentPath();
        var parent:Null<VariationNode> = variation.getNode(parentPath);
        var ply:Null<RawPly> = map.get(path);

        if (ply == null)
            throw 'Node not found in map (path $path)';
        else 
        {
            if (parent == null)
                addPlyFromMapToVariation(variation, map, parentPath);
            variation.addChild(parentPath, ply);
        }
    }

    public function toVariation():Variation
    {
        var variation:Variation = new Variation(startingSituation);
        
        for (path => _ in plys.keyValueIterator())
            addPlyFromMapToVariation(variation, plys, path);

        return variation;
    }

    public function new(startingSituation:Situation, plys:VariationMap<RawPly>)
    {
        this.startingSituation = startingSituation;
        this.plys = plys;
    }
}
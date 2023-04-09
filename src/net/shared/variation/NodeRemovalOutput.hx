package net.shared.variation;

class NodeRemovalOutput 
{
    public final pathsRemoved:Array<VariationPath>;
    public final pathUpdates:Array<{oldPath:VariationPath, newPath:VariationPath}>;

    /**
        Paths that used to point to a node before removal, but now are missing from the variation
    **/
    public function freedPaths():Array<VariationPath>
    {
        var paths:Array<VariationPath> = [];

        for (update in pathUpdates)
            if (!Lambda.exists(pathUpdates, u -> u.newPath.equals(update.oldPath)))
                paths.push(update.oldPath);

        for (removedPath in pathsRemoved)
            if (!Lambda.exists(pathUpdates, u -> u.newPath.equals(removedPath)))
                paths.push(removedPath);

        return paths;
    }

    /**
        Paths that existed in the variation before removal and now are pointing to a new node
    **/
    public function remappedPaths():Array<VariationPath>
    {
        var paths:Array<VariationPath> = [];

        for (update in pathUpdates)
            if (Lambda.exists(pathUpdates, u -> u.oldPath.equals(update.newPath)) || Lambda.exists(pathsRemoved, p -> p.equals(update.newPath)))
                paths.push(update.newPath);

        return paths;
    }

    /**
        Paths that weren't present in the variation before removal, but appeared after
    **/
    public function addedPaths():Array<VariationPath>
    {
        var paths:Array<VariationPath> = [];

        for (update in pathUpdates)
            if (!Lambda.exists(pathUpdates, u -> u.oldPath.equals(update.newPath)))
                paths.push(update.newPath);

        return paths;
    }

    public function new() 
    {
        pathsRemoved = [];
        pathUpdates = [];    
    }
}
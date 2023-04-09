package net.shared.variation;

class VariationPathAncestorsIterator
{
    private var path:VariationPath;
    private var includeSelf:Bool;

    private var currentPath:Null<VariationPath>;
    private var i:Int;
    private var len:Int;
  
    public function new(path:VariationPath, includeSelf:Bool) 
    {
        this.path = path;
        this.includeSelf = includeSelf;
        
        this.currentPath = null;
        this.i = -1;
        this.len = path.length;
    }

    public function hasNext():Bool
    {
        if (includeSelf)
            return i < len;
        else
            return i < len - 1;
    }

    public function next():VariationPath
    {
        currentPath = currentPath == null? [] : currentPath.childPath(path[i]);
        i++;
        return currentPath;
    }
}
package net.shared.variation;

class VariationPathKVIterator
{
    private var path:VariationPath;
    private var i:Int;
    private var len:Int;
  
    public function new(path:VariationPath) 
    {
        this.path = path;
        this.i = 0;
        this.len = path.length;
    }

    public function hasNext()
    {
        return i < len;
    }

    public function next()
    {
        i++;
        return {key: i, value: path[i]};
    }
}
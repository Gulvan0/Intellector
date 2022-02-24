package analysis;

import haxe.Int64;

abstract ZobristMap<T>(Map<Int, Map<Int, T>>)
{
    public function zget(k:Int64):T
    {
        var innerMap = this.get(k.high);
        if (innerMap == null)
            return null
        else 
            return innerMap.get(k.low);
    }

    public function zset(k:Int64, v:T)
    {
        var innerMap = this.get(k.high);
        if (innerMap == null)
            this.set(k.high, [k.low => v]);
        else 
            innerMap.set(k.low, v);
    }

    public function new() 
    {
        this = [];
    }
}
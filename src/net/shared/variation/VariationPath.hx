package net.shared.variation;

abstract VariationPath(Array<Int>) from Array<Int> to Array<Int>
{
    public var length(get, never):Int;

    private function get_length():Int
    {
        return this.length;
    }

    public function asArray():Array<Int>
    {
        return this;
    }

    @:arrayAccess 
    public inline function get(index:Int):Int 
    {
        return this[index];
    }

    public function iterator():VariationPathIterator
    {
        return new VariationPathIterator(this);
    }

    public function keyValueIterator():VariationPathKVIterator
    {
        return new VariationPathKVIterator(this);
    }

    public function ancestorPathsIterator(includeSelf:Bool):VariationPathAncestorsIterator
    {
        return new VariationPathAncestorsIterator(this, includeSelf);
    }

    public function isRoot():Bool
    {
        return Lambda.empty(this);
    }

    public function isMainLine(?lineStartNodePath:VariationPath):Bool
    {
        if (lineStartNodePath == null)
            lineStartNodePath = VariationPath.root();

        var level:Int = 0;

        for (childNum in lineStartNodePath)
        {
            if (childNum != this[level])
                return false;
            level++;
        }

        for (childNum in this.slice(level))
            if (childNum != 0)
                return false;

        return true;
    }

    public function subpath(length:Int):VariationPath
    {
        return this.slice(0, length);
    }

    public function last():Int
    {
        return this[this.length - 1];
    }

    public function parentPath():Null<VariationPath>
    {
        return isRoot()? null : this.slice(0, -1);
    }

    public function childPath(num:Int):VariationPath
    {
        return this.concat([num]);
    }

    public function isDescendantOf(supposedAncestorPath:VariationPath, ?admitEqualPaths:Bool = true)
    {
        for (level => childNum in supposedAncestorPath.keyValueIterator())
            if (childNum != this[level])
                return false;

        return admitEqualPaths || supposedAncestorPath.length < this.length;
    }

    public function equals(p:VariationPath):Bool
    {
        for (level => childNum in p.keyValueIterator())
            if (childNum != this[level])
                return false;

        return p.length == this.length;
    }

    public function copy():VariationPath
    {
        return this.copy();
    }

    public function serialize():String
    {
        return this.join(":");
    }

    public function toString():String
    {
        return serialize();
    }

    public static function deserialize(str:String):VariationPath
    {
        return str == ''? [] : str.split(":").map(Std.parseInt);
    }

    public static function root():VariationPath
    {
        return [];
    }
}
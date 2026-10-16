package client.datatypes.variations;

/**
    A node's place in a `PlyTree`: the index of each child taken from the root down. Studies store
    it run-length encoded: `childIndex` (empty for 0) plus `x<repetitions>` when repeated, runs
    joined by `:` - so `[0, 0, 1, 0]` is `x2:1:`.
**/
abstract PlyTreePath(Array<Int>)
{
    public function new(childIndices:Array<Int>)
    {
        this = childIndices;
    }

    public static function of(node:PlyTreeNode):PlyTreePath
    {
        var indices:Array<Int> = [];
        var current:PlyTreeNode = node;
        while (!current.isRoot())
        {
            indices.unshift(current.parent.children.indexOf(current));
            current = current.parent;
        }
        return new PlyTreePath(indices);
    }

    public static function fromStudyString(path:String):PlyTreePath
    {
        var indices:Array<Int> = [];
        for (run in path.split(":"))
        {
            var parts:Array<String> = run.split("x");
            var childIndex:Int = parts[0] != "" ? Std.parseInt(parts[0]) : 0;
            var repetitions:Int = parts.length > 1 ? Std.parseInt(parts[1]) : 1;
            for (_ in 0...repetitions)
                indices.push(childIndex);
        }
        return new PlyTreePath(indices);
    }

    public function toStudyString():String
    {
        var runs:Array<String> = [];
        var i:Int = 0;
        while (i < this.length)
        {
            var repetitions:Int = 1;
            while (i + repetitions < this.length && this[i + repetitions] == this[i])
                repetitions++;

            var run:String = this[i] != 0 ? Std.string(this[i]) : "";
            if (repetitions > 1)
                run += 'x$repetitions';
            runs.push(run);
            i += repetitions;
        }
        return runs.join(":");
    }

    public function childIndices():Array<Int>
    {
        return this.copy();
    }

    /** The path one step up; the root's own path stays empty **/
    public function parent():PlyTreePath
    {
        return new PlyTreePath(this.slice(0, -1));
    }

    /** The node at this path in `tree`, if there is one **/
    public function find(tree:PlyTree):Null<PlyTreeNode>
    {
        var node:PlyTreeNode = tree.root;
        for (index in this)
        {
            if (index < 0 || index >= node.children.length)
                return null;
            node = node.children[index];
        }
        return node;
    }

    /** Orders parents before their children and children by index **/
    public static function compare(a:PlyTreePath, b:PlyTreePath):Int
    {
        var aIndices:Array<Int> = a.childIndices();
        var bIndices:Array<Int> = b.childIndices();
        for (i in 0...Std.int(Math.min(aIndices.length, bIndices.length)))
            if (aIndices[i] != bIndices[i])
                return aIndices[i] - bIndices[i];
        return aIndices.length - bIndices.length;
    }
}

package struct;

import haxe.ui.util.Variant;
import struct.Ply;

class VariantNode
{
    public var ply:Ply;
    public var plyStr:String;
    public var children:Map<String, VariantNode>;

    public function addChild(ply:Ply, plyStr:String) 
    {
        children.set(plyStr, new VariantNode(ply, plyStr, []));
    }

    public function c(plyStr:String) 
    {
        return children.get(plyStr);
    }

    public function removeChild(plyStr:String) 
    {
        children.remove(plyStr);
    }

    public function new(ply:Ply, plyStr:String, children:Map<String, VariantNode>) 
    {
        this.ply = ply;
        this.plyStr = plyStr;
        this.children = children;
    }
}

class Variant extends VariantNode 
{
    public function new() 
    {
        super(new Ply(), "root", []);    
    }
}
package net.shared.dataobj;

import net.shared.variation.ReadOnlyVariation;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.variation.VariationMap;

class StudyInfo
{
    public var id:Int;
    public var ownerLogin:String;
    public var name:String;
    public var description:String;
    public var tags:Array<String>;
    public var publicity:StudyPublicity;
    public var keyPositionSIP:String;

    public var startingSituationSIP:String;
    public var lightVariation:VariationMap<RawPly>;

    public function toString():String 
    {
        return 'StudyInfo(Name=$name)';
    }

    public function assignVariation(variation:ReadOnlyVariation)
    {
        this.lightVariation = variation.collectNodes(false).map(x -> x.getIncomingPly());
        this.startingSituationSIP = variation.rootNode().getSituation();
    }

    public function excludeNonParameters()
    {
        this.id = -1;
        this.ownerLogin = "";
    }

    public function new()
    {

    }
}
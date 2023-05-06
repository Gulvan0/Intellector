package net.shared.dataobj;

import net.shared.variation.PlainVariation;
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

    public var plainVariation:PlainVariation;

    public function toString():String 
    {
        return 'StudyInfo(Name=$name)';
    }

    public function assignVariation(variation:ReadOnlyVariation)
    {
        this.plainVariation = PlainVariation.fromVariation(variation);
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
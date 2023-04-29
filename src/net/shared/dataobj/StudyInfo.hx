package net.shared.dataobj;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.variation.VariationMap;

class StudyInfo
{
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

    public function new()
    {

    }
}
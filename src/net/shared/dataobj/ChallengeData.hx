package net.shared.dataobj;

import net.shared.EloValue.serialize;

class ChallengeData
{
    public var id:Int;
    public var serializedParams:String;
    public var ownerLogin:String;
    public var ownerELO:EloValue;

    public function toString() 
    {
        return 'ChallengeData(ID=$id, Owner=$ownerLogin)';
    }

    public function new()
    {
        
    }
}
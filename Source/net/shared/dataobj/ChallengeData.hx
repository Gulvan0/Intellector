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
        return 'ChallengeData {\nID: $id\nSerialized params: $serializedParams\nOwner: $ownerLogin (${serialize(ownerELO)})\n}';
    }

    public function new()
    {
        
    }
}
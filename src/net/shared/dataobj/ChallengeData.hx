package net.shared.dataobj;

class ChallengeData
{
    public var id:Int;
    public var params:ChallengeParams;
    public var ownerLogin:String;
    public var ownerELO:EloValue;

    public function toString() 
    {
        return 'ChallengeData(ID=$id, Owner=$ownerLogin, $params)';
    }

    public function new()
    {
        
    }
}
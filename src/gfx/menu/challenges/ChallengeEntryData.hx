package gfx.menu.challenges;

import struct.ChallengeParams;
import net.shared.dataobj.ChallengeData;

class ChallengeEntryData
{
    public var id:Int;
    public var params:ChallengeParams;
    public var ownerLogin:String;
    public var list:ChallengeList;

    public function new(data:ChallengeData, list:ChallengeList)
    {
        this.id = data.id;
        this.params = ChallengeParams.deserialize(data.serializedParams);
        this.ownerLogin = data.ownerLogin;
        this.list = list;
    }
}
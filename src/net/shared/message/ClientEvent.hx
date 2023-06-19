package net.shared.message;

import net.shared.Subscription;
import net.shared.utils.UnixTimestamp;
import net.shared.dataobj.*;
import net.shared.board.RawPly;

enum ClientEvent
{
    LogOut;

    CancelChallenge(challengeID:Int);
    AcceptChallenge(challengeID:Int); 
    DeclineDirectChallenge(challengeID:Int);

    Move(ply:RawPly); 
    Message(text:String); 
    SimpleRematch;
    Resign; 
    PerformOfferAction(kind:OfferKind, action:OfferAction);
    AddTime; 

    BotGameRollback(plysReverted:Int, updatedTimestamp:Null<UnixTimestamp>);
    BotMessage(text:String);
    
    OverwriteStudy(overwrittenStudyID:Int, info:StudyInfo);
    DeleteStudy(id:Int);

    AddFriend(login:String);
    RemoveFriend(login:String);
}
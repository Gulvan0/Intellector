package net.shared.dataobj;

import net.shared.dataobj.ChallengeData;

enum SendChallengeResult
{
    Success(data:ChallengeData); //challenge created successfully; ID was assigned to it
    ToOneself; //the callee and caller are the same player
    PlayerNotFound; //player does not exist
    AlreadyExists; //a player has already sent a challenge to this callee
    Duplicate; //a similar challenge (i. e. with the same params) already exists
    RematchExpired; //sent simple rematch request, but the challenge params TTL has already expired
    Impossible; //some other crucial condition is not met (e. g., a player isn't in Browsing state)
    Merged; //merged with other compatible challenge
}
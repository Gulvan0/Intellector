package net.shared;

enum SendChallengeResult
{
    Success(challengeID:Int, serializedParams:String); //challenge created successfully; ID was assigned to it
    ToOneself; //the callee and caller are the same player
    PlayerNotFound; //player does not exist
    AlreadyExists; //a player has already sent a challenge to this callee
}
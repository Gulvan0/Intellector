package net.shared;

enum SendChallengeResult
{
    Success; //challenge sent
    ToOneself; //the callee and caller are the same player
    PlayerNotFound; //player does not exist
    AlreadyExists; //a player has already sent a challenge to this callee
}
package net.shared;

import net.shared.ChallengeData;

enum SendChallengeResult
{
    Success(data:ChallengeData); //challenge created successfully; ID was assigned to it
    ToOneself; //the callee and caller are the same player
    PlayerNotFound; //player does not exist
    AlreadyExists; //a player has already sent a challenge to this callee
    RematchExpired; //sent simple rematch request, but the challenge params TTL has already expired
    Impossible; //some other crucial condition is not met (e. g., a player isn't in Browsing state)
    Merged; //merged with other compatible challenge
}
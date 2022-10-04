package net.shared;

import net.shared.ChallengeData;

enum SendChallengeResult
{
    Success(data:ChallengeData); //challenge created successfully; ID was assigned to it
    ToOneself; //the callee and caller are the same player
    PlayerNotFound; //player does not exist
    AlreadyExists; //a player has already sent a challenge to this callee
}
package net.models.challenge;

enum abstract ChallengeCreateResult(String) from String to String
{
    var CREATED;
    var MERGED;
}

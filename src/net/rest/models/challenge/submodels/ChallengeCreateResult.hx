package net.rest.models.challenge.submodels;

enum abstract ChallengeCreateResult(String) from String to String
{
    var CREATED;
    var MERGED;
}

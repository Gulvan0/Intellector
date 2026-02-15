package net.rest.models.challenge.submodels;

enum abstract ChallengeAcceptorColor(String) from String to String
{
    var WHITE = "white";
    var BLACK = "black";
    var RANDOM = "random";
}

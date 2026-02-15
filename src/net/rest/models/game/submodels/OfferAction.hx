package net.rest.models.game.submodels;

enum abstract OfferAction(String) from String to String
{
    var CREATE = "create";
    var CANCEL = "cancel";
    var ACCEPT = "accept";
    var DECLINE = "decline";
}

package net.rest.models.player.submodels;

enum abstract UserRole(String) from String to String
{
    var ADMIN = "admin";
    var ANACONDA_DEVELOPER = "anaconda_developer";
}

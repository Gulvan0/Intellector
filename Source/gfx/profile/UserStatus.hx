package gfx.profile;

enum UserStatus
{
    Offline(secondsSinceLastAction:Int);
    Online;
    InGame;
}
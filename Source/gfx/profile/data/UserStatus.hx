package gfx.profile.data;

enum UserStatus
{
    Offline(secondsSinceLastAction:Int);
    Online;
    InGame;
}
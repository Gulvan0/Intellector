package net.shared.dataobj;

enum UserStatus
{
    Offline(secondsSinceLastAction:Int);
    Online;
    InGame;
}
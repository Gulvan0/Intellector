package net.shared;

enum UserStatus
{
    Offline(secondsSinceLastAction:Int);
    Online;
    InGame;
}
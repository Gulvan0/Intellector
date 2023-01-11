package net.shared;

enum TimeControlType
{
    Hyperbullet;
    Bullet;
    Blitz;
    Rapid;
    Classic;
    Correspondence;
}

function isSecondLongerThanFirst(tc1:TimeControlType, tc2:TimeControlType)
{
    return tc1.getIndex() < tc2.getIndex();
}
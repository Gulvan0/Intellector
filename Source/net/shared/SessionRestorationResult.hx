package net.shared;

enum SessionRestorationResult
{
    Restored(missedEvents:Array<ServerEvent>);
    NotRestored;
}
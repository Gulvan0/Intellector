package net.shared.dataobj;

enum SessionRestorationResult
{
    Restored(missedEvents:Array<ServerEvent>);
    NotRestored;
}
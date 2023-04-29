package net;

import net.shared.ServerEvent;

interface INetObserver 
{
    public function handleNetEvent(event:ServerEvent):Void;
}
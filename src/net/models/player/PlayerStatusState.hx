package net.models.player;

import jsonmodel.IJsonUnserializableMacro;

class PlayerStatusState implements IJsonUnserializableMacro
{
    public var status:UserStatus;
    @:default(null) public var last_active_unixsecs:Null<Int>; // unknown for a player who hasn't been connected since the server started watching them
}

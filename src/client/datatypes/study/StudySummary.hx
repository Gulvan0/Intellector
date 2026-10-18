package client.datatypes.study;

import intellectorboard.position.Position;

/** A study as listed: what it's called and about, its tags, and the position it centres on **/
class StudySummary
{
    public final id:Int;
    public final name:String;
    public final description:String;
    public final tags:Array<String>;
    public final keyPosition:Position;

    public function new(id:Int, name:String, description:String, tags:Array<String>, keyPosition:Position)
    {
        this.id = id;
        this.name = name;
        this.description = description;
        this.tags = tags;
        this.keyPosition = keyPosition;
    }
}

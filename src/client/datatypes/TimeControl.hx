package client.datatypes;

import client.datatypes.FischerTimeControl;

@:using(client.datatypes.TimeControl.TimeControlExtension)
enum TimeControl  //TODO: Use everywhere instead of dto TimeControl and struct's TimeControl
{
    None;
    Fischer(instance:FischerTimeControl);
}

class TimeControlExtension
{
    public function getKind(timeControl:TimeControl):TimeControlKind
    {
        return switch timeControl {
            case None: Correspondence;
            case Fischer(instance): instance.getKind();
        }
    }
}

class TimeControlFactory
{
    public static function constructFischer(startMins:Float, bonusSecs:Int):TimeControl
    {
        return Fischer(new FischerTimeControl(Math.round(startMins * 60), bonusSecs));
    }
}

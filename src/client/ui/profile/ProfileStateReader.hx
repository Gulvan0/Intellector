package client.ui.profile;

import client.ui.profile.ProfileState.ArchiveState;
import client.ui.profile.ProfileState.OngoingGamesState;

/** Validates a navigation state read back from the browser, dropping whatever doesn't fit **/
class ProfileStateReader
{
    public static function read(raw:Dynamic):ProfileState
    {
        if (raw == null || !Reflect.isObject(raw))
            return {};

        return {
            ongoing: readOngoing(Reflect.field(raw, "ongoing")),
            archive: readArchive(Reflect.field(raw, "archive"))
        };
    }

    private static function readOngoing(raw:Dynamic):Null<OngoingGamesState>
    {
        if (raw == null || !Reflect.isObject(raw))
            return null;

        return {
            correspondence: Reflect.field(raw, "correspondence") == true,
            kinds: readStrings(Reflect.field(raw, "kinds")),
            rated: readRated(Reflect.field(raw, "rated"))
        };
    }

    private static function readArchive(raw:Dynamic):Null<ArchiveState>
    {
        if (raw == null || !Reflect.isObject(raw))
            return null;

        return {
            studies: Reflect.field(raw, "studies") == true,
            kinds: readStrings(Reflect.field(raw, "kinds")),
            rated: readRated(Reflect.field(raw, "rated")),
            pastPage: readNaturalNumber(Reflect.field(raw, "pastPage"), 1),
            tags: readStrings(Reflect.field(raw, "tags")),
            studyOffset: readNaturalNumber(Reflect.field(raw, "studyOffset"), 0)
        };
    }

    private static function readStrings(raw:Dynamic):Array<String>
    {
        if (!Std.isOfType(raw, Array))
            return [];

        var values:Array<Dynamic> = raw;
        return [for (value in values) if (Std.isOfType(value, String)) value];
    }

    private static function readRated(raw:Dynamic):Null<Bool>
    {
        return Std.isOfType(raw, Bool) ? raw : null;
    }

    private static function readNaturalNumber(raw:Dynamic, minimum:Int):Int
    {
        return Std.isOfType(raw, Int) && raw >= minimum ? raw : minimum;
    }
}

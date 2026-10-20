package client.utils;

/** Paths of the app's pages, in the form `HaxeFolioApp.navigateTo` and `PageLink` take **/
class PagePaths
{
    /** `null` for a guest or a bot: they have no profile **/
    public static function playerProfile(userRef:String):Null<String>
    {
        if (StringTools.startsWith(userRef, "_") || StringTools.startsWith(userRef, "+"))
            return null;

        return 'player/$userRef';
    }

    public static function liveGame(gameId:Int):String
    {
        return 'live/$gameId';
    }

    public static function study(studyId:Int):String
    {
        return 'study/$studyId';
    }
}

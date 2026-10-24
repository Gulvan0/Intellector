package client.ui.profile;

typedef OngoingGamesState =
{
    correspondence:Bool,
    kinds:Array<String>,
    rated:Null<Bool>
}

typedef ArchiveState =
{
    studies:Bool,
    kinds:Array<String>,
    rated:Null<Bool>,
    pastPage:Int,
    tags:Array<String>,
    /** Index of the first study shown, so the page survives a change of the page size **/
    studyOffset:Int
}

/** What the profile page keeps in the navigation state to survive a reload; the stats and connections cards keep none **/
typedef ProfileState =
{
    ?ongoing:OngoingGamesState,
    ?archive:ArchiveState
}

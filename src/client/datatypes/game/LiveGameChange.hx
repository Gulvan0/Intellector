package client.datatypes.game;

/** What part of a `LiveGameState` changed **/
enum LiveGameChange
{
    /** `appended`: the one message added, or null if the whole chat was replaced **/
    Chat(appended:Null<GameChatMessage>);
    Offers;
    Clock;
    Ended;
}

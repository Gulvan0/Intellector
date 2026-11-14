package client.datatypes.games;

enum PlayerValue
{
    User(login:String);
    Guest(id:Int);
    Bot(filter:BotFilter);
}

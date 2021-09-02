package url;

enum Section
{
    Main;
    OpenChallengeInvitation(issuer:String);
    Game(id:Int);
    Profile(login:String);
}
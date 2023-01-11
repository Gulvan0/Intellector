package net.shared.dataobj;

enum ViewedScreen 
{
    MainMenu;
    Game(id:Int);
    Analysis;
    Profile(ownerLogin:String);
    Other;
}
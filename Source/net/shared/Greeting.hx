package net.shared;

enum Greeting
{
    Simple;
    Login(login:String, password:String);
    Reconnect(token:String);
}
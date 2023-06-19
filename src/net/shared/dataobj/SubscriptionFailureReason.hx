package net.shared.dataobj;

enum SubscriptionFailureReason 
{
    FollowPlayerNotFound; //Follow: player does not exist
    FollowAlreadySpectating(id:Int); //Follow: added to follower list, but the game is already viewed by client
    FollowSuccess; //Follow: no current game to spectate, but the player will be notified when the followed player starts playing    
}
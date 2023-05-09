package gfx.scene;

import haxe.ui.core.Component;

interface IPublicScene
{
    public function toScreen(initializer:Null<ScreenInitializer>):Void;
    public function displaySubscreen(subscreen:Component):Void; 
    public function returnToMainScene():Void;
    public function refreshTitleAndUrl():Void;
    public function isUserParticipatingInOngoingFiniteGame():Bool;
    public function refreshLanguage():Void;
    public function removeEntryFromChallengeList(challengeID:Int):Void;
}
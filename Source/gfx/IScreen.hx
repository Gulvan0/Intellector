package gfx;

import haxe.ui.core.Component;
import js.Browser;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import openfl.display.Sprite;

interface IScreen
{
    public function onEntered():Void;
    public function onClosed():Void;
    public function menuHidden():Bool;
    public function asComponent():Component;
}
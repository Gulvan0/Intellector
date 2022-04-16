package gfx.common;

import haxe.ui.containers.ButtonBar;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/action_bar.xml"))
class ActionBar extends ButtonBar
{
    public function new() 
    {
        super();    
    }
}
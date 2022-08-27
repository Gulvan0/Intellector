package gfx;

import haxe.ui.containers.SideBar;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/basic/sidemenu.xml'))
class SideMenu extends SideBar
{
    public function new()
    {
        super();
    }
}
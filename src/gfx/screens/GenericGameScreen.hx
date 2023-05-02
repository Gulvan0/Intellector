package gfx.screens;

import haxe.ui.core.Component;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import net.shared.dataobj.ViewedScreen;
import dict.Phrase;

abstract class GenericGameScreen extends Screen
{
    public abstract function getTitle():Null<Phrase>;
    public abstract function getURLPath():Null<String>;
    public abstract function getPage():ViewedScreen;

    private abstract function onEnter():Void;
    private abstract function onClose():Void;

    private function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
    {
        return [];
    }

    public function new()
    {
        super();
    }
}
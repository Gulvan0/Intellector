package gfx.screens;

import haxe.ui.core.Component;
import haxe.ui.containers.HBox;

class LanguageSelectIntro extends HBox implements IScreen
{
    //TODO: Fill

    public function onEntered()
    {
        //* Do nothing
    }

    public function onClosed()
    {
        //* Do nothing
    }

    public function menuHidden():Bool
    {
        return true;
    }

    public function asComponent():Component
    {
        return this;
    }

    public function new()
    {
        super();
    }
}
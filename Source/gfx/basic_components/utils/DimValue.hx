package gfx.basic_components.utils;

import haxe.ui.core.Component;

enum DimValue
{
    Auto;
    Exact(v:Float);
    Percent(v:Float);
}

function assignWidth(comp:Component, value:DimValue)
{
    switch value 
    {
        case Auto:
            comp.percentWidth = null;
            comp.width = null;
        case Exact(v):
            comp.percentWidth = null;
            comp.width = v;
        case Percent(v):
            comp.width = null;
            comp.percentWidth = v;
    }
}

function assignHeight(comp:Component, value:DimValue)
{
    switch value 
    {
        case Auto:
            comp.percentHeight = null;
            comp.height = null;
        case Exact(v):
            comp.percentHeight = null;
            comp.height = v;
        case Percent(v):
            comp.height = null;
            comp.percentHeight = v;
    }
}
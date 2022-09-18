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
            comp.width = null;
        case Exact(v):
            comp.width = v;
        case Percent(v):
            comp.percentWidth = v;
    }
}

function assignHeight(comp:Component, value:DimValue)
{
    switch value 
    {
        case Auto:
            comp.height = null;
        case Exact(v):
            comp.height = v;
        case Percent(v):
            comp.percentHeight = v;
    }
}
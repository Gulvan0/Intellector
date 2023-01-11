package gfx.common;

import struct.Variant;
import gfx.game.LiveGameConstructor;

enum ComponentConstructor 
{
    Live(constr:LiveGameConstructor);
    Analysis(initialVariant:Variant);    
}
package gfx.game.interfaces;

import gfx.utils.SpecialControlSettings;

interface IGameScreenGetters 
{
    public function getBehaviour():IBehaviour;
    public function getSpecialControlSettings():SpecialControlSettings;
}
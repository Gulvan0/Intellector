package gfx.preloader;

import haxe.ui.Preloader;

@:xml('
    <preloader width="100%" height="100%">
        <image resource="assets/preloader.gif" horizontalAlign="center" verticalAlign="center" />
    </preloader>
')
class DefaultPreloader extends Preloader 
{
    public function new() 
    {
        super();
    }    
}
package client.ui.common.board.layers;

/**
    One of `BoardSurface`'s stacked SVG groups. Keeps its own state keyed by hex coordinates, not
    SVG handles, and draws only into its own group.
**/
interface BoardLayer
{
    /** Redraws the group from the stored state, e.g. after a projection or palette change **/
    public function redraw():Void;
}

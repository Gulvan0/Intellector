package client.ui.common.board.layers;

/**
    One of `BoardSurface`'s stacked SVG groups. Keeps its own state keyed by hex coordinates
    (never SVG handles as the source of truth) and draws only into its own group.
**/
interface BoardLayer
{
    /**
        Clears the layer's group and draws it again from its stored state, e.g. after the board's
        projection or palette changed.
    **/
    public function redraw():Void;
}

package gfx.game.events;

import net.shared.variation.VariationPath;

enum VariationViewEvent
{
    NodeSelected(path:VariationPath);
    NodeRemoved(path:VariationPath);
}
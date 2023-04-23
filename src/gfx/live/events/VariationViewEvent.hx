package gfx.live.events;

import net.shared.variation.VariationPath;

enum VariationViewEvent
{
    NodeSelected(path:VariationPath);
    NodeRemoved(path:VariationPath);
}
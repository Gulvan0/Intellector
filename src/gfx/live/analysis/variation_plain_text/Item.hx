package gfx.live.analysis.variation_plain_text;

import haxe.ui.components.Label;

enum Item
{
    LBrace(label:Label);
    RBrace(label:Label, ownerInfo:NodeInfo);
    Node(info:NodeInfo);
}
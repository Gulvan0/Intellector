package gfx.menu;

import assets.Paths;
import dict.Phrase;

class MenuItem
{
    public final itemName:MenuItemName;
    public final displayName:Phrase;
    public final itemIconPath:String;

    private function getDisplayName(itemName:MenuItemName):Phrase
    {
        return MENU_ITEM_NAME(itemName);
    }

    private function getIconPath(itemName:MenuItemName):String
    {
        return Paths.menuItem(itemName);
    }

    public function new(itemName:MenuItemName)
    {
        this.itemName = itemName;
        
        displayName = getDisplayName(itemName);
        itemIconPath = getIconPath(itemName);
    }
}
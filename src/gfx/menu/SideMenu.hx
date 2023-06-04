package gfx.menu;

import gfx.ResponsiveToolbox.ResponsiveProperty;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import dict.Phrase;
import dict.Dictionary;
import haxe.ui.components.Label;
import haxe.ui.containers.SideBar;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/menu/side_menu.xml'))
class SideMenu extends SideBar 
{
    private var sectionHeaders:Map<MenuSection, Label> = [];
    private var itemLabels:Map<MenuItemName, Label> = [];

    public function refreshLanguage()
    {
        for (section => header in sectionHeaders.keyValueIterator())
            header.text = Dictionary.getPhrase(MENU_SECTION_TITLE(section));

        for (itemName => itemLabel in itemLabels.keyValueIterator())
            itemLabel.text = Dictionary.getPhrase(MENU_ITEM_NAME(itemName));
    }

    public function resize()
    {
        var siteNameRules:Map<ResponsiveProperty, ResponsivenessRule> = [StyleProp(PaddingLeft) => VH(1), StyleProp(PaddingRight) => VH(1), StyleProp(FontSize) => VH(3)];
        var mobileMenuButtonRules:Map<ResponsiveProperty, ResponsivenessRule> = [Width => VH(2.6), Height => VH(2.2)];
        var mobileMenuHeaderRules:Map<ResponsiveProperty, ResponsivenessRule> = [StyleProp(FontSize) => VH(1.75)];
        var mobileMenuItemRules:Map<ResponsiveProperty, ResponsivenessRule> = [StyleProp(FontSize) => VH(1.5)];

        ResponsiveToolbox.resizeComponent(siteName, siteNameRules);
        ResponsiveToolbox.resizeComponent(mobileMenuButton, mobileMenuButtonRules);
        ResponsiveToolbox.resizeComponent(mainSpacer, [Height => VH(2)]);
        for (header in findComponents('mobileMenuHeader'))
            ResponsiveToolbox.resizeComponent(header, mobileMenuHeaderRules);
        for (item in findComponents('mobileMenuItem'))
            ResponsiveToolbox.resizeComponent(item, mobileMenuItemRules);
        for (spacer in findComponents('sectionSpacer'))
            ResponsiveToolbox.resizeComponent(spacer, [Height => VH(1)]);
    }

    public function new(sections:Array<MenuSection>, items:Map<MenuSection, Array<MenuItem>>, clickHandler:MenuItemName->Void, onSiteNamePressed:Void->Void)
    {
        super();

        var currentPos:Int = 2; //After mobileMenuButton and siteTitle, but before everything else

        for (section in sections)
        {
            var sectionHeader:Label = new Label();
            sectionHeader.text = Dictionary.getPhrase(MENU_SECTION_TITLE(section));
            sectionHeader.styleNames = "mobileMenuHeader";

            sectionHeaders.set(section, sectionHeader);
            contentBox.addComponentAt(sectionHeader, currentPos);

            for (item in items.get(section))
            {
                var itemLabel:Label = new Label();
                itemLabel.text = Dictionary.getPhrase(item.displayName);
                itemLabel.styleNames = "mobileMenuItem";
                itemLabel.onClick = e -> {
                    hide();
                    clickHandler(item.itemName);
                };

                itemLabels.set(item.itemName, itemLabel);
                contentBox.addComponent(itemLabel);
            }

            currentPos++;
        }

        mobileMenuButton.onClick = e -> {
            hide();
        };
        siteName.onClick = e -> {
            hide();
            onSiteNamePressed();
        };
    }
}
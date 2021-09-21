package gfx.screens;

import gfx.components.gamefield.modules.Field;
import gfx.components.gamefield.modules.Field.Markup;
import haxe.ui.styles.Style;
import js.Cookie;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import js.Browser;
import dict.Dictionary;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.components.OptionBox;
import openfl.display.Sprite;

class Settings extends Sprite
{
    private var markupOptionBoxes:Map<Markup, OptionBox> = [];

    public function new()
    {
		super();
        var box:VBox = new VBox();

		var header:Label = new Label();
		header.text = Dictionary.getPhrase(SETTINGS_TITLE);
		header.customStyle = {fontSize: 16};
		header.horizontalAlign = "center";
		box.addComponent(header);

		box.addComponent(buildMarkupRow());
		box.addComponent(buildLangRow());

		box.x = (Browser.window.innerWidth - 290) / 2;
		box.y = 100;
		addChild(box);

		var returnBtn = new Button();
		returnBtn.width = 100;
		returnBtn.text = Dictionary.getPhrase(RETURN);
		returnBtn.onClick = (e) -> {ScreenManager.instance.toMain();};
            
        returnBtn.x = 10;
	    returnBtn.y = 10;
	    addChild(returnBtn);
    }    

    private function buildMarkupRow():HBox
    {
        var markup:HBox = new HBox();

		var markupLabel:Label = new Label();
		markupLabel.text = Dictionary.getPhrase(SETTINGS_MARKUP_TITLE);
		markup.addComponent(markupLabel);

        for (type in Markup.createAll())
        {
            var optionBox:OptionBox = new OptionBox();
            optionBox.text = Dictionary.getMarkupOptionText(type);
            optionBox.componentGroup = "settings-markup";
            optionBox.onChange = (e) -> {
                if (optionBox.selected)
                {
                    Field.markup = type;
                    Cookie.set("markup", type.getName(), 60 * 60 * 24 * 365 * 5);
                }
            };
            markupOptionBoxes[type] = optionBox;
            markup.addComponent(optionBox);
        }

        markupOptionBoxes[Field.markup].selected = true;
        return markup;
    }

    private function buildLangRow():HBox
    {
        var lang:HBox = new HBox();

		var langLabel:Label = new Label();
		langLabel.text = Dictionary.getPhrase(SETTINGS_LANGUAGE_TITLE);
		lang.addComponent(langLabel);

		var langEN:OptionBox = new OptionBox();
		langEN.text = "English";
		langEN.componentGroup = "settings-lang";
		lang.addComponent(langEN);

		var langRU:OptionBox = new OptionBox();
		langRU.text = "Русский";
		langRU.componentGroup = "settings-lang";
		lang.addComponent(langRU);

		switch Dictionary.lang
		{
			case EN: langEN.selected = true;
			case RU: langRU.selected = true;
		}
		
		langEN.onChange = (e) -> {
			if (langEN.selected)
			{
				Dictionary.lang = EN;
				Cookie.set("lang", "EN", 60 * 60 * 24 * 365 * 5);
			}
		};
		langRU.onChange = (e) -> {
			if (langRU.selected)
			{
				Dictionary.lang = RU;
				Cookie.set("lang", "RU", 60 * 60 * 24 * 365 * 5);
			}
        };

        return lang;
    }
}
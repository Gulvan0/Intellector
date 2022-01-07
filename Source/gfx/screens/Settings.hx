package gfx.screens;

import Preferences.Markup;
import dict.Language;
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
                    Preferences.markup = type;
                    Cookie.set("markup", type.getName(), 60 * 60 * 24 * 365 * 5);
                }
            };
            markupOptionBoxes[type] = optionBox;
            markup.addComponent(optionBox);
        }

        markupOptionBoxes[Preferences.markup].selected = true;
        return markup;
    }

    private function buildLangRow():HBox
    {
        var languageSelector:HBox = new HBox();

		var langLabel:Label = new Label();
		langLabel.text = Dictionary.getPhrase(SETTINGS_LANGUAGE_TITLE);
		languageSelector.addComponent(langLabel);

		for (language in Language.createAll())
			languageSelector.addComponent(createLangOptionBox(language));

        return languageSelector;
	}
	
	private function createLangOptionBox(lang:Language):OptionBox
	{
		var option:OptionBox = new OptionBox();
		option.text = Dictionary.getLanguageName(lang);
		option.componentGroup = "settings-lang";
		option.onChange = (e) -> {
			if (option.selected)
				Preferences.instance.language = lang;
		};
		if (Preferences.language == lang)
			option.selected = true;
		return option;
	}
}
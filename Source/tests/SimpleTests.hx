package tests;

import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import utils.AssetManager;
import gfx.basic_components.AnnotatedImage;
import haxe.ui.core.Screen;
import gfx.basic_components.AutosizingLabel;

class SimpleTests 
{
    public static function autosizingLabel()
    {
		var v = new AutosizingLabel();
		v.customStyle = {backgroundColor: 0xff0000, backgroundOpacity: 0.5};
		v.percentWidth = 100;
		v.text = "Lorem ipsum dolor sit amet";
		v.horizontalAlign = 'center';
		v.verticalAlign = 'center';
		Screen.instance.addComponent(v);
	}
	
	public static function annotatedImage()
	{
		var vbox:VBox = new VBox();
		vbox.percentWidth = 100;
		vbox.verticalAlign = "center";

		var images:Array<AnnotatedImage> = [
			new AnnotatedImage(Exact(500), Exact(100), AssetManager.timeControlPath(Blitz), "3+2", true, "Blitz"),
			new AnnotatedImage(Auto, Exact(100), AssetManager.timeControlPath(Rapid), "10+15", true, "Rapid"),
			new AnnotatedImage(Percent(50), Exact(100), AssetManager.timeControlPath(Correspondence), "Correspondence", true)
		];

		for (image in images)
		{
			image.customStyle = {horizontalAlign: 'center', backgroundColor: 0xff0000, backgroundOpacity: 0.5};

			var newStyle:Style = image.img.customStyle.clone();
			newStyle.backgroundColor = 0xffff00;
			newStyle.backgroundOpacity = 0.5;
			image.img.customStyle = newStyle;
	
			var newStyle:Style = image.lbl.customStyle.clone();
			newStyle.backgroundColor = 0xffff00;
			newStyle.backgroundOpacity = 0.5;
			image.lbl.customStyle = newStyle;

			vbox.addComponent(image);
		}

		Screen.instance.addComponent(vbox);
	}
}
package;


import haxe.io.Bytes;
import lime.utils.AssetBundle;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets;

#if sys
import sys.FileSystem;
#end

@:access(lime.utils.Assets)


@:keep @:dox(hide) class ManifestResources {


	public static var preloadLibraries:Array<AssetLibrary>;
	public static var preloadLibraryNames:Array<String>;
	public static var rootPath:String;


	public static function init (config:Dynamic):Void {

		preloadLibraries = new Array ();
		preloadLibraryNames = new Array ();

		rootPath = null;

		if (config != null && Reflect.hasField (config, "rootPath")) {

			rootPath = Reflect.field (config, "rootPath");

		}

		if (rootPath == null) {

			#if (ios || tvos || emscripten)
			rootPath = "assets/";
			#elseif android
			rootPath = "";
			#elseif console
			rootPath = lime.system.System.applicationDirectory;
			#else
			rootPath = "./";
			#end

		}

		#if (openfl && !flash && !display)
		openfl.text.Font.registerFont (__ASSET__OPENFL__fonts_roboto_medium_ttf);
		openfl.text.Font.registerFont (__ASSET__OPENFL__fonts_roboto_regular_ttf);
		
		#end

		var data, manifest, library, bundle;

		#if kha

		null
		library = AssetLibrary.fromManifest (manifest);
		Assets.registerLibrary ("null", library);

		if (library != null) preloadLibraries.push (library);
		else preloadLibraryNames.push ("null");

		#else

		data = '{"name":null,"assets":"aoy4:pathy27:styles%2Fdefault%2Fmain.cssy4:sizei1135y4:typey4:TEXTy2:idR1y7:preloadtgoR0y17:styles%2Fmain.cssR2i148R3R4R5R7R6tgoR2i171320R3y4:FONTy9:classNamey32:__ASSET__fonts_roboto_medium_ttfR5y25:fonts%2FRoboto-Medium.ttfR6tgoR0y26:fonts%2FRoboto-Regular.eotR2i163058R3y6:BINARYR5R12R6tgoR0y26:fonts%2FRoboto-Regular.svgR2i240120R3R4R5R14R6tgoR2i162876R3R8R9y33:__ASSET__fonts_roboto_regular_ttfR5y26:fonts%2FRoboto-Regular.ttfR6tgoR0y27:fonts%2FRoboto-Regular.woffR2i86488R3R13R5R17R6tgoR0y28:fonts%2FRoboto-Regular.woff2R2i19960R3R13R5R18R6tgoR0y38:assets%2Ffigures%2FAggressor_black.pngR2i11433R3y5:IMAGER5R19R6tgoR0y38:assets%2Ffigures%2FAggressor_white.pngR2i11685R3R20R5R21R6tgoR0y37:assets%2Ffigures%2FDefensor_black.pngR2i13534R3R20R5R22R6tgoR0y37:assets%2Ffigures%2FDefensor_white.pngR2i13132R3R20R5R23R6tgoR0y38:assets%2Ffigures%2FDominator_black.pngR2i14027R3R20R5R24R6tgoR0y38:assets%2Ffigures%2FDominator_white.pngR2i14289R3R20R5R25R6tgoR0y40:assets%2Ffigures%2FIntellector_black.pngR2i13664R3R20R5R26R6tgoR0y40:assets%2Ffigures%2FIntellector_white.pngR2i13928R3R20R5R27R6tgoR0y38:assets%2Ffigures%2FLiberator_black.pngR2i11674R3R20R5R28R6tgoR0y38:assets%2Ffigures%2FLiberator_white.pngR2i11443R3R20R5R29R6tgoR0y39:assets%2Ffigures%2FProgressor_black.pngR2i9640R3R20R5R30R6tgoR0y39:assets%2Ffigures%2FProgressor_white.pngR2i9684R3R20R5R31R6tgh","rootPath":null,"version":2,"libraryArgs":[],"libraryType":null}';
		manifest = AssetManifest.parse (data, rootPath);
		library = AssetLibrary.fromManifest (manifest);
		Assets.registerLibrary ("default", library);
		

		library = Assets.getLibrary ("default");
		if (library != null) preloadLibraries.push (library);
		else preloadLibraryNames.push ("default");
		

		#end

	}


}


#if kha

null

#else

#if !display
#if flash

@:keep @:bind @:noCompletion #if display private #end class __ASSET__styles_default_main_css extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__styles_main_css extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__fonts_roboto_medium_ttf extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_eot extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_svg extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_ttf extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_woff extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_woff2 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_aggressor_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_aggressor_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_defensor_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_defensor_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_dominator_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_dominator_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_intellector_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_intellector_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_liberator_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_liberator_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_progressor_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figures_progressor_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__manifest_default_json extends null { }


#elseif (desktop || cpp)

@:keep @:file("C:/HaxeToolkit/haxe/lib/haxeui-openfl/1,0,0/./assets/styles/default/main.css") @:noCompletion #if display private #end class __ASSET__styles_default_main_css extends haxe.io.Bytes {}
@:keep @:file("C:/HaxeToolkit/haxe/lib/haxeui-openfl/1,0,0/./assets/styles/main.css") @:noCompletion #if display private #end class __ASSET__styles_main_css extends haxe.io.Bytes {}
@:keep @:font("Export/html5/obj/webfont/Roboto-Medium.ttf") @:noCompletion #if display private #end class __ASSET__fonts_roboto_medium_ttf extends lime.text.Font {}
@:keep @:file("C:/HaxeToolkit/haxe/lib/haxeui-openfl/1,0,0/./assets/fonts/Roboto-Regular.eot") @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_eot extends haxe.io.Bytes {}
@:keep @:file("C:/HaxeToolkit/haxe/lib/haxeui-openfl/1,0,0/./assets/fonts/Roboto-Regular.svg") @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_svg extends haxe.io.Bytes {}
@:keep @:font("Export/html5/obj/webfont/Roboto-Regular.ttf") @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_ttf extends lime.text.Font {}
@:keep @:file("C:/HaxeToolkit/haxe/lib/haxeui-openfl/1,0,0/./assets/fonts/Roboto-Regular.woff") @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_woff extends haxe.io.Bytes {}
@:keep @:file("C:/HaxeToolkit/haxe/lib/haxeui-openfl/1,0,0/./assets/fonts/Roboto-Regular.woff2") @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_woff2 extends haxe.io.Bytes {}
@:keep @:image("Assets/figures/Aggressor_black.png") @:noCompletion #if display private #end class __ASSET__assets_figures_aggressor_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Aggressor_white.png") @:noCompletion #if display private #end class __ASSET__assets_figures_aggressor_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Defensor_black.png") @:noCompletion #if display private #end class __ASSET__assets_figures_defensor_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Defensor_white.png") @:noCompletion #if display private #end class __ASSET__assets_figures_defensor_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Dominator_black.png") @:noCompletion #if display private #end class __ASSET__assets_figures_dominator_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Dominator_white.png") @:noCompletion #if display private #end class __ASSET__assets_figures_dominator_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Intellector_black.png") @:noCompletion #if display private #end class __ASSET__assets_figures_intellector_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Intellector_white.png") @:noCompletion #if display private #end class __ASSET__assets_figures_intellector_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Liberator_black.png") @:noCompletion #if display private #end class __ASSET__assets_figures_liberator_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Liberator_white.png") @:noCompletion #if display private #end class __ASSET__assets_figures_liberator_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Progressor_black.png") @:noCompletion #if display private #end class __ASSET__assets_figures_progressor_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figures/Progressor_white.png") @:noCompletion #if display private #end class __ASSET__assets_figures_progressor_white_png extends lime.graphics.Image {}
@:keep @:file("") @:noCompletion #if display private #end class __ASSET__manifest_default_json extends haxe.io.Bytes {}



#else

@:keep @:expose('__ASSET__fonts_roboto_medium_ttf') @:noCompletion #if display private #end class __ASSET__fonts_roboto_medium_ttf extends lime.text.Font { public function new () { #if !html5 __fontPath = "fonts/Roboto-Medium"; #else ascender = 1900; descender = -500; height = 2400; numGlyphs = 1294; underlinePosition = -200; underlineThickness = 100; unitsPerEM = 2048; #end name = "Roboto Medium"; super (); }}
@:keep @:expose('__ASSET__fonts_roboto_regular_ttf') @:noCompletion #if display private #end class __ASSET__fonts_roboto_regular_ttf extends lime.text.Font { public function new () { #if !html5 __fontPath = "fonts/Roboto-Regular"; #else ascender = 1900; descender = -500; height = 2400; numGlyphs = 1250; underlinePosition = -200; underlineThickness = 100; unitsPerEM = 2048; #end name = "Roboto"; super (); }}


#end

#if (openfl && !flash)

#if html5
@:keep @:expose('__ASSET__OPENFL__fonts_roboto_medium_ttf') @:noCompletion #if display private #end class __ASSET__OPENFL__fonts_roboto_medium_ttf extends openfl.text.Font { public function new () { __fromLimeFont (new __ASSET__fonts_roboto_medium_ttf ()); super (); }}
@:keep @:expose('__ASSET__OPENFL__fonts_roboto_regular_ttf') @:noCompletion #if display private #end class __ASSET__OPENFL__fonts_roboto_regular_ttf extends openfl.text.Font { public function new () { __fromLimeFont (new __ASSET__fonts_roboto_regular_ttf ()); super (); }}

#else
@:keep @:expose('__ASSET__OPENFL__fonts_roboto_medium_ttf') @:noCompletion #if display private #end class __ASSET__OPENFL__fonts_roboto_medium_ttf extends openfl.text.Font { public function new () { __fromLimeFont (new __ASSET__fonts_roboto_medium_ttf ()); super (); }}
@:keep @:expose('__ASSET__OPENFL__fonts_roboto_regular_ttf') @:noCompletion #if display private #end class __ASSET__OPENFL__fonts_roboto_regular_ttf extends openfl.text.Font { public function new () { __fromLimeFont (new __ASSET__fonts_roboto_regular_ttf ()); super (); }}

#end

#end
#end

#end

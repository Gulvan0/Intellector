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
		
		#end

		var data, manifest, library, bundle;

		#if kha

		null
		library = AssetLibrary.fromManifest (manifest);
		Assets.registerLibrary ("null", library);

		if (library != null) preloadLibraries.push (library);
		else preloadLibraryNames.push ("null");

		#else

		data = '{"name":null,"assets":"aoy4:pathy38:assets%2Ffigures%2FAggressor_black.pngy4:sizei11433y4:typey5:IMAGEy2:idR1y7:preloadtgoR0y38:assets%2Ffigures%2FAggressor_white.pngR2i11685R3R4R5R7R6tgoR0y37:assets%2Ffigures%2FDefensor_black.pngR2i13534R3R4R5R8R6tgoR0y37:assets%2Ffigures%2FDefensor_white.pngR2i13132R3R4R5R9R6tgoR0y38:assets%2Ffigures%2FDominator_black.pngR2i14027R3R4R5R10R6tgoR0y38:assets%2Ffigures%2FDominator_white.pngR2i14289R3R4R5R11R6tgoR0y40:assets%2Ffigures%2FIntellector_black.pngR2i13664R3R4R5R12R6tgoR0y40:assets%2Ffigures%2FIntellector_white.pngR2i13928R3R4R5R13R6tgoR0y38:assets%2Ffigures%2FLiberator_black.pngR2i11674R3R4R5R14R6tgoR0y38:assets%2Ffigures%2FLiberator_white.pngR2i11443R3R4R5R15R6tgoR0y39:assets%2Ffigures%2FProgressor_black.pngR2i9640R3R4R5R16R6tgoR0y39:assets%2Ffigures%2FProgressor_white.pngR2i9684R3R4R5R17R6tgh","rootPath":null,"version":2,"libraryArgs":[],"libraryType":null}';
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



#end

#if (openfl && !flash)

#if html5

#else

#end

#end
#end

#end

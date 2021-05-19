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

		data = '{"name":null,"assets":"aoy4:sizei5987y4:typey5:MUSICy2:idy20:sounds%2Fcapture.mp3y9:pathGroupaR4hy7:preloadtgoR0i10448R1R2R3y27:sounds%2Fchallenge_sent.mp3R5aR7hR6tgoR0i4285R1R2R3y17:sounds%2Fmove.mp3R5aR8hR6tgoR0i8011R1R2R3y19:sounds%2Fnotify.mp3R5aR9hR6tgoR0i62644R1R2R3y19:sounds%2Fsocial.mp3R5aR10hR6tgoy4:pathy20:assets%2Ffavicon.pngR0i17461R1y5:IMAGER3R12R6tgoR11y39:assets%2Ffigicons%2FAggressor_black.pngR0i12342R1R13R3R14R6tgoR11y39:assets%2Ffigicons%2FAggressor_white.pngR0i12566R1R13R3R15R6tgoR11y38:assets%2Ffigicons%2FDefensor_black.pngR0i14981R1R13R3R16R6tgoR11y38:assets%2Ffigicons%2FDefensor_white.pngR0i15362R1R13R3R17R6tgoR11y39:assets%2Ffigicons%2FDominator_black.pngR0i14756R1R13R3R18R6tgoR11y39:assets%2Ffigicons%2FDominator_white.pngR0i15008R1R13R3R19R6tgoR11y39:assets%2Ffigicons%2FLiberator_black.pngR0i12576R1R13R3R20R6tgoR11y39:assets%2Ffigicons%2FLiberator_white.pngR0i12354R1R13R3R21R6tgoR11y38:assets%2Ffigures%2FAggressor_black.pngR0i11433R1R13R3R22R6tgoR11y38:assets%2Ffigures%2FAggressor_white.pngR0i11685R1R13R3R23R6tgoR11y37:assets%2Ffigures%2FDefensor_black.pngR0i13534R1R13R3R24R6tgoR11y37:assets%2Ffigures%2FDefensor_white.pngR0i13132R1R13R3R25R6tgoR11y38:assets%2Ffigures%2FDominator_black.pngR0i14027R1R13R3R26R6tgoR11y38:assets%2Ffigures%2FDominator_white.pngR0i14289R1R13R3R27R6tgoR11y40:assets%2Ffigures%2FIntellector_black.pngR0i13664R1R13R3R28R6tgoR11y40:assets%2Ffigures%2FIntellector_white.pngR0i13928R1R13R3R29R6tgoR11y38:assets%2Ffigures%2FLiberator_black.pngR0i11674R1R13R3R30R6tgoR11y38:assets%2Ffigures%2FLiberator_white.pngR0i11443R1R13R3R31R6tgoR11y39:assets%2Ffigures%2FProgressor_black.pngR0i9640R1R13R3R32R6tgoR11y39:assets%2Ffigures%2FProgressor_white.pngR0i9684R1R13R3R33R6tgoR11y32:assets%2Flayouts%2Fmovetable.xmlR0i288R1y4:TEXTR3R34R6tgoR0i5987R1R2R3y29:assets%2Fsounds%2Fcapture.mp3R5aR36hR6tgoR0i10448R1R2R3y36:assets%2Fsounds%2Fchallenge_sent.mp3R5aR37hR6tgoR0i4285R1R2R3y26:assets%2Fsounds%2Fmove.mp3R5aR38hR6tgoR0i8011R1R2R3y28:assets%2Fsounds%2Fnotify.mp3R5aR39hR6tgoR0i62644R1R2R3y28:assets%2Fsounds%2Fsocial.mp3R5aR40hR6tgh","rootPath":null,"version":2,"libraryArgs":[],"libraryType":null}';
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

@:keep @:bind @:noCompletion #if display private #end class __ASSET__sounds_capture_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__sounds_challenge_sent_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__sounds_move_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__sounds_notify_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__sounds_social_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_favicon_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_aggressor_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_aggressor_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_defensor_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_defensor_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_dominator_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_dominator_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_liberator_black_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_figicons_liberator_white_png extends flash.display.BitmapData { public function new () { super (0, 0, true, 0); } }
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
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_layouts_movetable_xml extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_sounds_capture_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_sounds_challenge_sent_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_sounds_move_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_sounds_notify_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__assets_sounds_social_mp3 extends null { }
@:keep @:bind @:noCompletion #if display private #end class __ASSET__manifest_default_json extends null { }


#elseif (desktop || cpp)

@:keep @:file("Assets/sounds/capture.mp3") @:noCompletion #if display private #end class __ASSET__sounds_capture_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/challenge_sent.mp3") @:noCompletion #if display private #end class __ASSET__sounds_challenge_sent_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/move.mp3") @:noCompletion #if display private #end class __ASSET__sounds_move_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/notify.mp3") @:noCompletion #if display private #end class __ASSET__sounds_notify_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/social.mp3") @:noCompletion #if display private #end class __ASSET__sounds_social_mp3 extends haxe.io.Bytes {}
@:keep @:image("Assets/favicon.png") @:noCompletion #if display private #end class __ASSET__assets_favicon_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Aggressor_black.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_aggressor_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Aggressor_white.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_aggressor_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Defensor_black.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_defensor_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Defensor_white.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_defensor_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Dominator_black.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_dominator_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Dominator_white.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_dominator_white_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Liberator_black.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_liberator_black_png extends lime.graphics.Image {}
@:keep @:image("Assets/figicons/Liberator_white.png") @:noCompletion #if display private #end class __ASSET__assets_figicons_liberator_white_png extends lime.graphics.Image {}
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
@:keep @:file("Assets/layouts/movetable.xml") @:noCompletion #if display private #end class __ASSET__assets_layouts_movetable_xml extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/capture.mp3") @:noCompletion #if display private #end class __ASSET__assets_sounds_capture_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/challenge_sent.mp3") @:noCompletion #if display private #end class __ASSET__assets_sounds_challenge_sent_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/move.mp3") @:noCompletion #if display private #end class __ASSET__assets_sounds_move_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/notify.mp3") @:noCompletion #if display private #end class __ASSET__assets_sounds_notify_mp3 extends haxe.io.Bytes {}
@:keep @:file("Assets/sounds/social.mp3") @:noCompletion #if display private #end class __ASSET__assets_sounds_social_mp3 extends haxe.io.Bytes {}
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

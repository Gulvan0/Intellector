package client.utils;

import haxe.macro.Expr;
#if macro
import sys.FileSystem;
#else
import js.html.Audio;
import js.html.Image;
#end

class AssetPreloader
{
    #if !macro
    private static inline final PARALLEL_LOADS:Int = 4;
    private static inline final HEAVY_IMAGE_FOLDER:String = "bot_avatars";

    private static var loadedImages:Array<Image> = [];
    private static var loadedSounds:Array<Audio> = [];
    private static var pendingImagePaths:Array<String>;

    /**
        Fetches every image and sound under `assets` so that components created later find them in the cache
        and don't lay out around a still-empty image. Large images go last.
    **/
    public static function start():Void
    {
        var imagePaths:Array<String> = listImagePaths();
        pendingImagePaths = imagePaths.filter(path -> path.indexOf(HEAVY_IMAGE_FOLDER) == -1).concat(imagePaths.filter(path -> path.indexOf(HEAVY_IMAGE_FOLDER) != -1));

        for (_ in 0...PARALLEL_LOADS)
            loadNextImage();

        for (path in listSoundPaths())
        {
            var audio:Audio = new Audio(path);
            audio.preload = "auto";
            loadedSounds.push(audio);
        }
    }

    private static function loadNextImage():Void
    {
        var path:Null<String> = pendingImagePaths.shift();
        if (path == null)
            return;

        var image:Image = new Image();
        image.onload = loadNextImage;
        image.onerror = loadNextImage;
        image.src = path;
        loadedImages.push(image);
    }
    #end

    private static macro function listImagePaths():Expr
    {
        return macro $v{collectFiles("assets/images")};
    }

    private static macro function listSoundPaths():Expr
    {
        return macro $v{collectFiles("assets/sounds")};
    }

    #if macro
    private static function collectFiles(folder:String):Array<String>
    {
        var paths:Array<String> = [];
        for (entry in FileSystem.readDirectory(folder))
        {
            var entryPath:String = '$folder/$entry';
            if (FileSystem.isDirectory(entryPath))
                paths = paths.concat(collectFiles(entryPath));
            else
                paths.push(entryPath);
        }
        return paths;
    }
    #end
}

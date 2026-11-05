package client.build;

import haxe.macro.Expr;
#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

class BuildInfoMacro
{
    /** The build ID as a string literal **/
    public static macro function embeddedBuildId():Expr
    {
        return macro $v{buildId()};
    }

    #if macro
    private static var timestamp:String = DateTools.format(Date.now(), "%Y%m%d%H%M%S");

    /** Registers the writing of `version.json` next to the compiled script **/
    public static function register():Void
    {
        Context.onAfterGenerate(writeVersionFile);
    }

    private static function buildId():String
    {
        if (Context.defined("debug"))
            return "dev";

        var revision:String = git(["rev-parse", "--short", "HEAD"]);
        var dirtySuffix:String = git(["status", "--porcelain"]) != "" ? "-dirty" : "";
        return '$revision$dirtySuffix-$timestamp';
    }

    private static function apiVersion():Int
    {
        var source:String = File.getContent(Context.resolvePath("Config.hx"));
        var pattern:EReg = ~/API_VERSION:Int = (\d+);/;
        if (!pattern.match(source))
            Context.fatalError("Config.API_VERSION not found", Context.currentPos());

        return Std.parseInt(pattern.matched(1));
    }

    private static function writeVersionFile():Void
    {
        var directory:String = Path.directory(Compiler.getOutput());
        if (!FileSystem.exists(directory))
            return;

        File.saveContent(Path.join([directory, "version.json"]), haxe.Json.stringify({build: buildId(), api: apiVersion()}));
    }

    private static function git(arguments:Array<String>):String
    {
        var process:Process = new Process("git", arguments);
        var output:String = StringTools.trim(process.stdout.readAll().toString());
        if (process.exitCode() != 0)
            Context.fatalError('git ${arguments.join(" ")} failed', Context.currentPos());
        process.close();
        return output;
    }
    #end
}

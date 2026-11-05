package client.errors;

import haxe.CallStack;
import haxe.Exception;
import js.html.ErrorEvent;
import js.html.Event;

/** Passes on the errors that would otherwise only reach the console: each distinct one once, up to a limit per page load **/
class ErrorReporter
{
    private static inline final MAX_REPORTS_PER_PAGE_LOAD:Int = 10;
    private static inline final MAX_MESSAGE_LENGTH:Int = 2000;
    private static inline final MAX_STACK_LENGTH:Int = 8000;
    private static inline final RESIZE_OBSERVER_NOTICE_PREFIX:String = "ResizeObserver loop"; // browsers raise it as an error, though nothing is wrong

    private static var send:Null<String->Null<String>->Void> = null;
    private static var reportedErrors:Map<String, Bool> = [];

    /** `send` gets the message and the stack, if any, each short enough for the server to accept **/
    public static function start(send:String->Null<String>->Void):Void
    {
        ErrorReporter.send = send;
        js.Browser.window.addEventListener("error", onWindowError);
        js.Browser.window.addEventListener("unhandledrejection", onUnhandledRejection);
    }

    /** For an error caught on the way: `context` tells what failed, `error` is what was caught **/
    public static function report(context:String, error:Dynamic):Void
    {
        submit('$context: ${describe(error)}', stackOf(error));
    }

    private static function onWindowError(event:ErrorEvent):Void
    {
        submit(event.message, stackOf(event.error) ?? '${event.filename}:${event.lineno}:${event.colno}');
    }

    private static function onUnhandledRejection(event:Event):Void
    {
        report("Unhandled rejection", Reflect.field(event, "reason"));
    }

    private static function submit(message:String, stack:Null<String>):Void
    {
        if (send == null || StringTools.startsWith(message, RESIZE_OBSERVER_NOTICE_PREFIX))
            return;

        var key:String = '$message\n$stack';
        if (reportedErrors.exists(key) || Lambda.count(reportedErrors) >= MAX_REPORTS_PER_PAGE_LOAD)
            return;
        reportedErrors.set(key, true);

        try
        {
            send(message.substr(0, MAX_MESSAGE_LENGTH), stack?.substr(0, MAX_STACK_LENGTH));
        }
        catch (e)
        {
            js.Browser.console.error("Failed to report an error", e); // reporting it would only fail the same way
        }
    }

    private static function describe(error:Dynamic):String
    {
        var message:Dynamic = error != null ? Reflect.field(error, "message") : null;
        return Std.isOfType(message, String) ? message : Std.string(error);
    }

    private static function stackOf(error:Dynamic):Null<String>
    {
        if (Std.isOfType(error, Exception))
        {
            var exception:Exception = error;
            var stack:CallStack = exception.stack;
            var items:Array<StackItem> = [for (i in 0...stack.length) stack[i]];
            return CallStack.toString(items.filter(item -> !item.match(Module(_)))); // the lines of a multi-line message get parsed into module items
        }

        var stack:Dynamic = error != null ? Reflect.field(error, "stack") : null;
        return Std.isOfType(stack, String) ? stack : null;
    }
}

package tests.ui;

import js.Cookie;
import haxe.crypto.Md5;

typedef EndpointCall = {method:String, attributes:Array<String>};
typedef Macros = Array<EndpointCall>;

//TODO: Rewrite completely
class CookieStore
{
    public var macroses:Map<String, Macros> = [];
    public var checks:Array<String> = [];
    
    private static function getCookieHash(method:String, num:Int, ?step:Int = -2):String 
    {
        return Md5.encode(method + step + num);
    }

    public function addCheck(method:String, num:Int, ?step:Int = -2) 
    {
        checks.push(getCookieHash(method, num, step));
        CookieKeeper.save();
    }

    public function removeCheck(method:String, num:Int, ?step:Int = -2) 
    {
        checks.remove(getCookieHash(method, num, step));
        CookieKeeper.save();
    }

    public function addMacros(name:String, macros:Macros) 
    {
        macroses.set(name, macros);
        CookieKeeper.save();
    }

    public function removeMacros(name:String) 
    {
        macroses.remove(name);
        CookieKeeper.save();
    }

    public function serialize():String
    {
        var s:String = checks.join("%");
        for (macrosName => macros in macroses.keyValueIterator())
        {
            s += "%%" + macrosName;
            for (methodCall in macros)
                s += "&" + methodCall.method + "%" + methodCall.attributes.join("%");
        }
        return s;
    }

    public function new(?serialized:String) 
    {
        if (serialized != null)
        {
            var doubleParts:Array<String> = serialized.split("%%");
            checks = doubleParts.shift().split("%");
            for (macrosStr in doubleParts)
            {
                var innerParts:Array<String> = macrosStr.split("&");
                var macrosName:String = innerParts.shift();
                var macros:Macros = [];
                for (callStr in innerParts)
                {
                    var singleParts:Array<String> = callStr.split("%");
                    var methodName:String = singleParts.shift();
                    macros.push({method: methodName, attributes: singleParts});
                }
                macroses.set(macrosName, macros);
            }
            
        }
    }
}

class CookieKeeper 
{
    private static inline final cookieName:String = 'ui';
    private static var ui_cookies:Map<String, CookieStore>;

    public static function get(className:String):CookieStore
    {
        var store = ui_cookies.get(className);
        if (store == null)
        {
            store = new CookieStore();
            ui_cookies.set(className, store);
        }

        return store;
    }

    public static function load() 
    {
        if (ui_cookies != null)
            return;

        var cookie = Cookie.get(cookieName);
        if (cookie == null)
            ui_cookies = [];
        else 
            for (classCookie in cookie.split("$$"))
            {
                var parts:Array<String> = classCookie.split("$");
                ui_cookies.set(parts[0], new CookieStore(parts[1]));
            }
    }

    public static function save() 
    {
        var s:String = "";
        for (className => store in ui_cookies.keyValueIterator())
            s += "$$" + className + "$" + store.serialize();

        Cookie.set(cookieName, s.substr(1), 60 * 60 * 24 * 365);
    }
}
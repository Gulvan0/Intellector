package;

import haxe.Http;
using StringTools;

class Telegram 
{
    public static function notifyAdmin(message:String) 
    {
        useMethod('sendMessage', ['chat_id' => Config.dict.getString("admin-tg-chat-id"), 'text' => message, 'parse_mode' => 'MarkdownV2']);
    }

    public static function useMethod(methodName:String, params:Map<String, String>) 
    {
        var token:String = Config.dict.getString("bot-token");
        var requestUrl:String = 'https://api.telegram.org/bot$token/$methodName';
        var http = new Http(requestUrl);

        for (paramName => paramValue in params.keyValueIterator())
        {
            var escaped:String = paramValue.replace('{', '\\{').replace('}', '\\}');
            http.addParameter(paramName, escaped);
        }
        
        http.request();
    }
}
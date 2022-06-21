package;

import haxe.Http;
using StringTools;

class Telegram 
{
    private static inline final requestUrlPrefix:String = 'https://api.telegram.org/bot' + Config.botToken + '/';

    public static function notifyAdmin(message:String) 
    {
        useMethod('sendMessage', ['chat_id' => Config.adminChatID, 'text' => message, 'parse_mode' => 'MarkdownV2']);
    }

    public static function useMethod(methodName:String, params:Map<String, String>) 
    {
        var http = new Http(requestUrlPrefix + methodName);

        for (paramName => paramValue in params.keyValueIterator())
        {
            var escaped:String = paramValue.replace('{', '\\{').replace('}', '\\}');
            http.addParameter(paramName, escaped);
        }
        
        http.request();
    }
}
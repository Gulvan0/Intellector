package;

import haxe.Http;

class Telegram 
{
    private static inline final requestUrlPrefix:String = 'https://api.telegram.org/bot' + Config.botToken + '/';

    public static function notifyAdmin(message:String) 
    {
        useMethod('sendMessage', ['chat_id' => Config.adminChatID, 'text' => message, 'parse_mode' => 'MarkdownV2']);
    }

    public static function useMethod(methodName:String, ?params:Map<String, String>) 
    {
        var url = requestUrlPrefix + methodName;

        if (params != null && !Lambda.empty(params))
        {
            var paramPairs:Array<String> = [];
            for (paramName => paramValue in params.keyValueIterator())
                paramPairs.push('$paramName=$paramValue');

            url += '?' + paramPairs.join('&');
        }
            
        var http = new Http(url);
        http.request();
    }
}
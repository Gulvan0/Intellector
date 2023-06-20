package net;

import net.shared.dataobj.GreetingResponseData;
import net.shared.message.ServerMessage;
import haxe.Unserializer;
import hx.ws.Types.MessageType;
import lzstring.LZString;
import hx.ws.Buffer;

class MessageProcessor 
{
    private static var eventQueue:EventProcessingQueue;
    private static var greetingResponseHandler:GreetingResponseData->Void;

    public static function init(eventQueue:EventProcessingQueue, greetingResponseHandler:GreetingResponseData->Void) 
    {
        MessageProcessor.eventQueue = eventQueue;
        MessageProcessor.greetingResponseHandler = greetingResponseHandler;
    }

    private static function decompressContent(bytesContent:Buffer)
    {
        var lz = new LZString();
        var base64:String = content.readAllAvailableBytes().toString();

        return lz.decompressFromBase64(base64);
    }

    private static function unserializeMessage(stringContent:String):ServerMessage
    {
        try
        {
            return Unserializer.run(stringContent);
        }
        catch (e)
        {
            trace("Failed to deserialize message: " + stringContent);
            trace(e);
            return null;
        }
    }

    private static function processString(stringContent:String) 
    {
        var message:ServerMessage = unserializeMessage(stringContent);

        if (message == null)
            return;

        switch message 
        {
            case GreetingResponse(data):
                greetingResponseHandler(data);
            case Event(id, event):
                eventQueue.processEvent(id, event);
            case RequestResponse(requestID, response):
                Requests.processResponse(requestID, response);
        }
    }

    public static function onMessageRecieved(msg:MessageType)
    {
        var stringContent:String = switch msg 
        {
            case BytesMessage(content): decompressContent(content);
            case StrMessage(content): content;
        }

        processString(stringContent);
    }
}
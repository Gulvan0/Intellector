package browser;

import js.Browser;
import gfx.Dialogs;

class Clipboard
{
    public static function copy(text:String, ?onSuccess:Null<Void->Void>) 
    {
        if (onSuccess != null)
            Browser.navigator.clipboard.writeText(text)
                .catchError(onCopyError)
                .finally(onSuccess);
        else
            Browser.navigator.clipboard.writeText(text)
                .catchError(onCopyError);
    }

    private static function onCopyError(e)
    {
        Dialogs.alert(CLIPBOARD_ERROR_ALERT_TEXT, CLIPBOARD_ERROR_ALERT_TITLE, ['$e']);
    }
}
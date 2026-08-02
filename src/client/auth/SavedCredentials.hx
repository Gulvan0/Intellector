package client.auth;

import haxefolio.HaxeFolioApp;

class SavedCredentials
{
    public final login:String;
    public final password:String;

    public function new(login:String, password:String)
    {
        this.login = login;
        this.password = password;
    }

    public static function getSavedLogin():Null<String>
    {
        return HaxeFolioApp.valueStorage.read(LocalStorageKey.SAVED_LOGIN);
    }

    public static function getSavedPassword():Null<String>
    {
        return HaxeFolioApp.valueStorage.read(LocalStorageKey.SAVED_PASSWORD);
    }

    public static function save(login:String, password:String, remember:Bool):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.SAVED_LOGIN, login);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.SAVED_PASSWORD, password);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.REMEMBER_ME, Std.string(remember));
    }

    public static function getRemembered():Null<SavedCredentials>
    {
        if (HaxeFolioApp.valueStorage.read(LocalStorageKey.REMEMBER_ME) != "true")
            return null;

        var login:Null<String> = getSavedLogin();
        var password:Null<String> = getSavedPassword();

        if (login == null || password == null)
            return null;

        return new SavedCredentials(login, password);
    }

    public static function eraseEverything():Void
    {
        HaxeFolioApp.valueStorage.remove(LocalStorageKey.REMEMBER_ME);
        HaxeFolioApp.valueStorage.remove(LocalStorageKey.SAVED_LOGIN);
        HaxeFolioApp.valueStorage.remove(LocalStorageKey.SAVED_PASSWORD);
    }

    public static function dontRemember():Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.REMEMBER_ME, "false");
    }
}

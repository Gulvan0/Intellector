package client.auth;

import haxefolio.HaxeFolioApp;

class IdentityKeeper
{
    public static var currentIdentity(default, null):Identity = Guest(null);

    private static var changeListeners:Array<Identity->Void>;

    public static function init(?initialChangeListeners:Array<Identity->Void>):Void
    {
        changeListeners = initialChangeListeners ?? [];
        HaxeFolioApp.valueStorage.addExternalChangeHandler(LocalStorageKey.IDENTITY, onExternalIdentityChange);
    }

    private static function updateKeeperIdentity(identity:Identity):Void
    {
        if (Type.enumEq(currentIdentity, identity))
            return;

        currentIdentity = identity;
        for (listener in changeListeners)
            listener(currentIdentity);
    }

    private static function onExternalIdentityChange(serializedIdentity:Null<String>):Void
    {
        var identity:Identity = IdentitySerializer.deserialize(serializedIdentity);
        updateKeeperIdentity(identity);
    }

    public static function updateIdentity(identity:Identity):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.IDENTITY, IdentitySerializer.serialize(identity));
        updateKeeperIdentity(identity);
    }

    public static function addChangeListener(callback:Identity->Void):Void
    {
        changeListeners.push(callback);
    }
}

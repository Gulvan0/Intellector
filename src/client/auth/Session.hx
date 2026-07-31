package client.auth;

import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;

class Session
{
	public static var currentLogin(default, null):Null<String>; // null = guest
	public static var currentNickname(default, null):Null<String>;

	private static final TOKEN_KEY:String = "session_token";
	private static final REMEMBER_ME_KEY:String = "session_remember_me";
	private static final CREDENTIALS_LOGIN_KEY:String = "session_credentials_login";
	private static final CREDENTIALS_PASSWORD_KEY:String = "session_credentials_password";

	private static var changeListeners:Array<Void->Void> = [];

	public static function isGuest():Bool
	{
		return currentLogin == null;
	}

	public static function currentToken():Null<String>
	{
		return HaxeFolioApp.valueStorage.read(TOKEN_KEY);
	}

	public static function rememberedCredentials():Null<{login:String, password:String}>
	{
		if (HaxeFolioApp.valueStorage.read(REMEMBER_ME_KEY) != "true")
			return null;

		var login:Null<String> = HaxeFolioApp.valueStorage.read(CREDENTIALS_LOGIN_KEY);
		var password:Null<String> = HaxeFolioApp.valueStorage.read(CREDENTIALS_PASSWORD_KEY);

		return (login != null && password != null) ? {login: login, password: password} : null;
	}

	public static function recordIdentity(token:String, identity:{user_ref:String, nickname:String}):Void
	{
		HaxeFolioApp.valueStorage.write(TOKEN_KEY, token);
		currentLogin = identity.user_ref;
		currentNickname = identity.nickname;
		notifyChanged();
	}

	public static function recordGuest(token:String, guestId:Int):Void
	{
		HaxeFolioApp.valueStorage.write(TOKEN_KEY, token);
		currentLogin = null;
		currentNickname = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.common.player.guest_name"), guestId);
		notifyChanged();
	}

	public static function forgetToken():Void
	{
		HaxeFolioApp.valueStorage.remove(TOKEN_KEY);
	}

	public static function forgetCredentials():Void
	{
		HaxeFolioApp.valueStorage.remove(REMEMBER_ME_KEY);
		HaxeFolioApp.valueStorage.remove(CREDENTIALS_LOGIN_KEY);
		HaxeFolioApp.valueStorage.remove(CREDENTIALS_PASSWORD_KEY);
	}

	public static function onSessionChanged(callback:Void->Void):Void
	{
		changeListeners.push(callback);
	}

	private static function notifyChanged():Void
	{
		for (listener in changeListeners)
			listener();
	}
}

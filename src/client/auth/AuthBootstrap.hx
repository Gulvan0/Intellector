package client.auth;

import haxe.Timer;
import haxefolio.HaxeFolioApp;
import http.HttpError;
import net.models.auth.AuthCredentials;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

class AuthBootstrap
{
    /*
        Backoff delays (ms) between retries of the same step on a transient failure (network error
        or 5xx). A 401 is never retried - it means the token/credentials are definitely invalid, so
        the chain moves on to the next step right away. Once delays are exhausted, the step also
        moves on to the next fallback rather than getting stuck.
    */
    private static final RETRY_DELAYS_MS:Array<Int> = [500, 1500, 4000];

    /*
        Silent-reauth chain run once at page load: stored token -> remembered credentials -> guest.
    */
    public static function run():Void
    {
        var token:Null<String> = HaxeFolioApp.valueStorage.read(LocalStorageKey.TOKEN);
        if (token == null)
        {
            signInWithRememberedCredentialsOrGuest();
            return;
        }

        attemptWhoami(0);
    }

    /*
        Drops the current session and re-enters the chain at the guest step, skipping remembered
        credentials (erased here) so the user isn't immediately signed back in.
    */
    public static function logOut():Void
    {
        HaxeFolioApp.valueStorage.remove(LocalStorageKey.TOKEN);
        SavedCredentials.eraseEverything();
        authAsGuest(0);
    }

    private static function attemptWhoami(retryCount:Int):Void
    {
        Rest.client().execute(
            RestOperationRegistry.WHOAMI,
            response -> {
                var identity:Identity = response.guest_id == null? Player(response.user_ref, response.nickname) : Guest(response.guest_id);
                IdentityKeeper.updateIdentity(identity);
            },
            error -> onStepError(error, retryCount, attemptWhoami, () -> {
                HaxeFolioApp.valueStorage.remove(LocalStorageKey.TOKEN);
                signInWithRememberedCredentialsOrGuest();
            })
        );
    }

    private static function signInWithRememberedCredentialsOrGuest():Void
    {
        var credentials:Null<SavedCredentials> = SavedCredentials.getRemembered();
        if (credentials == null)
        {
            authAsGuest(0);
            return;
        }

        attemptSignIn(credentials, 0);
    }

    private static function attemptSignIn(credentials:SavedCredentials, retryCount:Int):Void
    {
        Rest.client().execute(
            RestOperationRegistry.SIGN_IN,
            response -> {
                HaxeFolioApp.valueStorage.write(LocalStorageKey.TOKEN, response.token);
                IdentityKeeper.updateIdentity(Player(response.identity.user_ref, response.identity.nickname));
            },
            error -> onStepError(error, retryCount, retryCount -> attemptSignIn(credentials, retryCount), () -> {
                SavedCredentials.eraseEverything();
                authAsGuest(0);
            }),
            null,
            null,
            new AuthCredentials(credentials.login, credentials.password)
        );
    }

    private static function authAsGuest(retryCount:Int):Void
    {
        Rest.client().execute(
            RestOperationRegistry.AUTH_AS_GUEST,
            response -> {
                HaxeFolioApp.valueStorage.write(LocalStorageKey.TOKEN, response.token);
                IdentityKeeper.updateIdentity(Guest(response.guest_id));
            },
            error -> onStepError(error, retryCount, authAsGuest, () -> IdentityKeeper.updateIdentity(Guest(null)))
        );
    }

    /*
        A 401 (or delays exhausted) moves on to `onGiveUp` - the next step in the chain, or the
        terminal guest fallback. Any other failure (network error, 5xx, or a response that failed
        to deserialize) is treated as transient and retries the same step after a backoff delay.
    */
    private static function onStepError(error:HttpError, retryCount:Int, retryStep:Int->Void, onGiveUp:Void->Void):Void
    {
        if (error.httpStatus != 401 && retryCount < RETRY_DELAYS_MS.length)
        {
            Timer.delay(() -> retryStep(retryCount + 1), RETRY_DELAYS_MS[retryCount]);
            return;
        }

        onGiveUp();
    }
}

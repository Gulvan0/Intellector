package client.logic.challenge.creation;

import client.datatypes.challenge.creation.CalleeInput;
import utest.Assert;
import utest.Test;

class CalleeParsingTest extends Test
{
    private function testLoginNamesPlayer():Void
    {
        Assert.same(CalleeInput.Valid(Player("alice")), CalleeParsing.parseLogin("  alice ", null));
        Assert.same(CalleeInput.Valid(Player("a_b1")), CalleeParsing.parseLogin("a_b1", null));
    }

    private function testBlankLoginIsEmpty():Void
    {
        Assert.same(CalleeInput.Empty, CalleeParsing.parseLogin("   ", null));
    }

    private function testMalformedLoginIsInvalid():Void
    {
        Assert.same(CalleeInput.Invalid("invalid_login"), CalleeParsing.parseLogin("1alice", null));
        Assert.same(CalleeInput.Invalid("invalid_login"), CalleeParsing.parseLogin("al__ice", null));
        Assert.same(CalleeInput.Invalid("invalid_login"), CalleeParsing.parseLogin("alice_", null));
        Assert.same(CalleeInput.Invalid("invalid_login"), CalleeParsing.parseLogin("al ice", null));
    }

    private function testOwnLoginIsInvalid():Void
    {
        Assert.same(CalleeInput.Invalid("self"), CalleeParsing.parseLogin("alice", "alice"));
    }

    private function testLoginFieldTakesGuestInAnyNotation():Void
    {
        for (text in ["12", "#12", "_12", "Guest 12", "guest#12", "Гость #12", "ГОСТЬ12"])
            Assert.same(CalleeInput.Valid(Guest(12)), CalleeParsing.parseLogin(text, null), text);
    }

    private function testGuestNumberMustBePositive():Void
    {
        Assert.same(CalleeInput.Invalid("above_zero"), CalleeParsing.parseLogin("#0", null));
        Assert.same(CalleeInput.Invalid("above_zero"), CalleeParsing.parseGuestNumber("0", null));
    }

    private function testOwnGuestIsInvalid():Void
    {
        Assert.same(CalleeInput.Invalid("self"), CalleeParsing.parseLogin("Guest 12", "_12"));
        Assert.same(CalleeInput.Invalid("self"), CalleeParsing.parseGuestNumber("12", "_12"));
    }

    private function testGuestNumberFieldTakesDigitsOnly():Void
    {
        Assert.same(CalleeInput.Valid(Guest(7)), CalleeParsing.parseGuestNumber(" 7 ", null));
        Assert.same(CalleeInput.Empty, CalleeParsing.parseGuestNumber("", null));
        Assert.same(CalleeInput.Invalid("digits_only"), CalleeParsing.parseGuestNumber("#7", null));
        Assert.same(CalleeInput.Invalid("digits_only"), CalleeParsing.parseGuestNumber("seven", null));
    }
}

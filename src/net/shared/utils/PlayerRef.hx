package net.shared.utils;

using StringTools;

enum ConcretePlayerRef
{
    Normal(login:String);
    Guest(guestID:String);
    Bot(botHandle:String);
}

abstract PlayerRef(String) from String to String
{
    public function concretize():ConcretePlayerRef
    {
        return switch this.charAt(0) 
        {
            case "+": Bot(this.substr(1));
            case "_": Guest(this.substr(1));
            default: Normal(this);
        }
    }

    public function equals(ref:PlayerRef)
    {
        return switch [concretize(), ref.concretize()] 
        {
            case [Normal(login1), Normal(login2)]:
                login1.toLowerCase() == login2.toLowerCase();
            case [Guest(guestID1), Guest(guestID2)]:
                guestID1 == guestID2;
            case [Bot(botHandle1), Bot(botHandle2)]:
                botHandle1 == botHandle2;
            default:
                false;
        }
    }
}
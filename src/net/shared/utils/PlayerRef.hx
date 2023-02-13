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
}
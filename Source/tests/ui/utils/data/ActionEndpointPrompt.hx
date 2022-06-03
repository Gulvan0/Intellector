package tests.ui.utils.data;

class ActionEndpointPrompt
{
    public final displayName:String;    
    public final type:ArgumentType;
    public final defaultValues:Array<EndpointArgument>;

    private function checkConsistensy() 
    {
        for (arg in defaultValues)
            if (arg.type != type)
                throw 'Action endpoint prompt "$displayName" is inconsistent: one of default values has type ${arg.type}, which differs from the prompt type $type';
    }

    public function new(displayName:String, type:ArgumentType, ?defaultValues:Array<EndpointArgument>) 
    {
        this.displayName = displayName;
        this.type = type;

        if (defaultValues == null)
        {
            this.defaultValues = [];
            if (type == AEnumerable)
                throw 'Action endpoint requires AEnumerable prompt "$displayName", yet defaultValues is null';
        }
        else
        {
            this.defaultValues = defaultValues;
            checkConsistensy();
        }
    }
}
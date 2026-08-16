package client.ui.common.overlays.login;

import haxe.ui.containers.VBox;
import haxe.ui.components.TextField;
import haxe.ui.validators.IValidator;
import haxe.ui.events.UIEvent;

using haxe.ui.animation.AnimationTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/overlays/login/text_field_input_box.xml"))
class TextFieldInputBox extends VBox
{
    private final validationErrorRetrievers:Array<String->Null<String>>;

    public function new(ownValidators:Array<IValidator>, externalValidators:Array<String->Null<String>>, restrictChars:String, maxChars:Int, isPassword:Bool = false)
    {
        super();
        this.validationErrorRetrievers = externalValidators.concat([
            for (validator in ownValidators)
            _ -> validator.validate(inputTextfield)? validator.invalidMessage : null
        ]);

        inputTextfield.restrictChars = restrictChars;
        inputTextfield.maxChars = maxChars;
        inputTextfield.password = isPassword;
        inputTextfield.validators = ownValidators;
        inputTextfield.registerEvent(UIEvent.CHANGE, _ -> revalidate(false));

        revalidate(false);
    }

    public function getText():String
    {
        return inputTextfield.text;
    }

    public function revalidate(withFeedback:Bool):Bool
    {
        var errorMessage:Null<String> = null;

        for (retriever in validationErrorRetrievers)
        {
            errorMessage = retriever(inputTextfield.text);
            if (errorMessage != null)
                break;
        }

        if (errorMessage == null)
        {
            errorLabel.text = "";  // Just in case, to prevent stale text
            errorLabel.hidden = true;
            return true;
        }

        errorLabel.text = errorMessage;
        errorLabel.hidden = false;

        if (withFeedback)
            inputTextfield.shake().flash();

        return false;
    }
}

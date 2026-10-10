package client.ui.common.board.move_prompt;

/** A prompt on screen, awaiting the user's choice **/
interface OpenPrompt
{
    /** Takes the prompt off screen without calling back; safe to repeat **/
    public function close():Void;
}

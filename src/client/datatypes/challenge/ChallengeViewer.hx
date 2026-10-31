package client.datatypes.challenge;

/** Who is looking at a pending challenge, as far as what they may do with it **/
enum ChallengeViewer
{
    /** Its caller, who may cancel it **/
    Owner;
    /** Anyone but the caller for an open challenge, the callee for a direct one **/
    Acceptor;
    /** Anyone but the two players of a direct challenge **/
    Bystander;
}

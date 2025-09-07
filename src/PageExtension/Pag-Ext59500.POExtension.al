pageextension 59500 POExtension extends "Purchase Order"
{
    layout
    {
        addafter(Status)
        {
            field("Test Purchase Order"; Rec."Test Purchase Order")
            {
                ApplicationArea = All;
            }
            field("Target Receipt Date"; Rec."Target Receipt Date")
            {
                ApplicationArea = All;
            }
            field("First Receipt Date"; Rec."First Receipt Date")
            {
                ApplicationArea = All;
            }
            field("Receipt Delay"; Rec."Receipt Delay")
            {
                ApplicationArea = All;
            }
        }
    }
}

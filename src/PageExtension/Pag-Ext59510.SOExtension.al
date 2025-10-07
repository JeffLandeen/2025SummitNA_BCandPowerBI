pageextension 59510 SOExtension extends "Sales Order"
{
    layout
    {
        addafter(Status)
        {
            field("Test Sales Order"; Rec."Test Sales Order")
            {
                ApplicationArea = All;
            }
            field("Target Shipment Date"; Rec."Target Shipment Date")
            {
                ApplicationArea = All;
            }
            field("First Shipment Date"; Rec."First Shipment Date")
            {
                ApplicationArea = All;
            }
            field("Shipment Delay"; Rec."Shipment Delay")
            {
                ApplicationArea = All;
            }
        }
    }
}
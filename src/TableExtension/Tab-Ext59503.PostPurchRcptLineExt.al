tableextension 59503 PostPurchRcptLineExt extends "Purch. Rcpt. Line"
{
    fields
    {
        field(59500; "Test Purchase Order"; Boolean)
        {
            Caption = 'Test Purchase Order';
            ToolTip = 'Indicates whether the purchase line is part of a test purchase order.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}

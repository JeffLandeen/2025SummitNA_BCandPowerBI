tableextension 59502 PostPurchRcptHeaderExt extends "Purch. Rcpt. Header"
{
    fields
    {
        field(59500; "Test Purchase Order"; Boolean)
        {
            Caption = 'Test Purchase Order';
            DataClassification = SystemMetadata;
            ToolTip = 'Indicates whether the purchase order is a test purchase order.';
            Editable = false;
        }
    }
}

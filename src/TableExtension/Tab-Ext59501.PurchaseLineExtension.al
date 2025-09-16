tableextension 59501 PurchaseLineExtension extends "Purchase Line"
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

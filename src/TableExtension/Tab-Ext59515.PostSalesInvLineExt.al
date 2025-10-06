tableextension 59515 PostSalesInvLineExt extends "Sales Invoice Line"
{
    fields
    {
        field(59500; "Test Sales Order"; Boolean)
        {
            Caption = 'Test Sales Order';
            ToolTip = 'Indicates whether the sales line is part of a test sales order.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}

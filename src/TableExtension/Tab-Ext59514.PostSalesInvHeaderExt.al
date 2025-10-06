tableextension 59514 PostSalesInvHeaderExt extends "Sales Invoice Header"
{
    fields
    {
        field(59500; "Test Sales Order"; Boolean)
        {
            Caption = 'Test Sales Order';
            DataClassification = SystemMetadata;
            ToolTip = 'Indicates whether the sales order is a test sales order.';
            Editable = false;
        }
    }
}

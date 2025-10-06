tableextension 59510 "SalesHeader Extension" extends "Sales Header"
{
    fields
    {
        field(59500; "Test Sales Order"; Boolean)
        {
            Caption = 'Test Sales Order';
            DataClassification = SystemMetadata;
            ToolTip = 'Indicates whether the sales order is a test purchase order.';
            Editable = false;
        }
        field(59510; "Target Shipment Date"; Date)
        {
            Caption = 'Target Shipment Date';
            DataClassification = SystemMetadata;
            ToolTip = 'This is set to the Expected Receipt Date during the first release of the Sales Order';
            Editable = false;
        }
        field(59511; "First Shipment Date"; Date)
        {
            Caption = 'First Shipment Date';
            DataClassification = SystemMetadata;
            ToolTip = 'This is set to the post date of the first Sales Shipment associated with this Sales Order.';
            Editable = false;

            trigger OnValidate()
            begin
                CalculateShipmentDelay();
            end;
        }
        field(59512; "Receipt Delay"; Duration)
        {
            Caption = 'Receipt Delay';
            DataClassification = SystemMetadata;
            ToolTip = 'This is the difference in days between the Target Receipt Date and the First Receipt Date, will be negative value if the First Receipt Date is earlier than the Target Receipt Date.';
            Editable = false;
        }
    }

    local procedure CalculateShipmentDelay()
    begin
        if (Rec."Target Shipment Date" <> 0D) and (Rec."First Shipment Date" <> 0D) then
            Rec."Receipt Delay" := Rec."First Shipment Date" - Rec."Target Shipment Date"
        else
            Rec."Receipt Delay" := 0;
    end;
}

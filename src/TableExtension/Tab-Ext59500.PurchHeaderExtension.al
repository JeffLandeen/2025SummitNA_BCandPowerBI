tableextension 59500 "PurchHeader Extension" extends "Purchase Header"
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
        field(59510; "Target Receipt Date"; Date)
        {
            Caption = 'Target Receipt Date';
            DataClassification = SystemMetadata;
            ToolTip = 'This is set to the Expected Receipt Date during the first release of the Purchase Order';
            Editable = false;
        }
        field(59511; "First Receipt Date"; Date)
        {
            Caption = 'First Receipt Date';
            DataClassification = SystemMetadata;
            ToolTip = 'This is set to the post date of the first Purchase Receipt associated with this Purchase Order.';
            Editable = false;

            trigger OnValidate()
            begin
                CalculateReceiptDelay();
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

    local procedure CalculateReceiptDelay()
    begin
        if (Rec."Target Receipt Date" <> 0D) and (Rec."First Receipt Date" <> 0D) then
            Rec."Receipt Delay" := Rec."First Receipt Date" - Rec."Target Receipt Date"
        else
            Rec."Receipt Delay" := 0;
    end;
}

tableextension 59516 "Inventory Setup Extension" extends "Inventory Setup"
{
    fields
    {
        field(59500; "Test Doc. Location"; Code[10])
        {
            Caption = 'Test Doc. Location';
            DataClassification = CustomerContent;
            TableRelation = Location.Code where("Use As In-Transit" = const(false),
                                              "Require Put-away" = const(false),
                                              "Require Pick" = const(false),
                                              "Require Receive" = const(false),
                                              "Require Shipment" = const(false));
            ToolTip = 'Select a non warehouse managed location to use for creation of Test Purchase and Sales Order documents.';

            trigger OnValidate()
            var
                Location: Record Location;
                LocationNotFoundErr: Label 'Location %1 does not exist.', Comment = '%1 = Location Code';
                WhseLocationErr: Label 'Location %1 is warehouse managed. Please select a non-warehouse managed location.', Comment = '%1 = Location Code';
            begin
                if "Test Doc. Location" = '' then
                    exit;

                if not Location.Get("Test Doc. Location") then
                    Error(LocationNotFoundErr, "Test Doc. Location");

                if Location."Require Put-away" or
                   Location."Require Pick" or
                   Location."Require Receive" or
                   Location."Require Shipment" then
                    Error(WhseLocationErr, "Test Doc. Location");
            end;
        }
        field(59501; "Test Data Item Jnl. Template"; Code[10])
        {
            Caption = 'Test Data Item Jnl. Template';
            DataClassification = CustomerContent;
            TableRelation = "Item Journal Template";
            ToolTip = 'Specifies the item journal template to use for test data creation.';

            trigger OnValidate()
            begin
                if "Test Data Item Jnl. Template" <> xRec."Test Data Item Jnl. Template" then
                    Validate("Test Data Item Jnl. Batch", '');
            end;
        }
        field(59502; "Test Data Item Jnl. Batch"; Code[10])
        {
            Caption = 'Test Data Item Jnl. Batch';
            DataClassification = CustomerContent;
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Test Data Item Jnl. Template"));
            ToolTip = 'Specifies the item journal batch to use for test data creation.';
        }
    }
}
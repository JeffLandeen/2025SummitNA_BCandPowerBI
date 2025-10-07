pageextension 59516 "Inventory Setup Extension" extends "Inventory Setup"
{
    layout
    {
        addlast(content)
        {
            group("Testing Data")
            {
                Caption = 'Testing Data';

                field("Test Doc. Location"; Rec."Test Doc. Location")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a non warehouse managed location to use for creation of Test Purchase and Sales Order documents.';
                }
                field("Test Data Item Jnl. Template"; Rec."Test Data Item Jnl. Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item journal template to use for test data creation.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Test Data Item Jnl. Batch"; Rec."Test Data Item Jnl. Batch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item journal batch to use for test data creation.';
                }
            }
        }
    }
}
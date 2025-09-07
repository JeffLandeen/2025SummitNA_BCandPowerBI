pageextension 59501 "PurchOrderList Ext" extends "Purchase Order List"
{
    layout
    {
        addafter(Status)
        {
            field("Test Purchase Order"; Rec."Test Purchase Order")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addbefore(Post)
        {
            action("Generate Test Purchase Orders")
            {
                ApplicationArea = All;
                Caption = 'Generate Test Purchase Orders';
                Image = CreateBinContent;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Generate 100 test purchase orders with random vendors and items.';

                trigger OnAction()
                var
                    CreateTestPOs: Codeunit "Create Test POs";
                begin
                    CreateTestPOs.GenerateTestPurchaseOrders();
                end;
            }
        }
    }

}

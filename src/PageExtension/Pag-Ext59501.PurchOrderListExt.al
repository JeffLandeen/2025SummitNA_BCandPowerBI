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
            field(SystemCreatedAt; Rec.SystemCreatedAt)
            {
                ApplicationArea = All;
                Caption = 'Created At';
                ToolTip = 'Date and time when the record was created.';
                Editable = false;
            }
            field(SystemCreatedBy; Rec.SystemCreatedBy)
            {
                ApplicationArea = All;
                Caption = 'Created By';
                ToolTip = 'User ID of the user who created the record.';
                Editable = false;
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
            action("Generate and Post Test POs")
            {
                ApplicationArea = All;
                Caption = 'Generate & Post Test POs';
                Image = PostInventoryToGLTest;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Will Generate 100 new random POs, and post all existing Test POs (Receipts and Invoices).';

                trigger OnAction()
                var
                    CreateTestPOs: Codeunit "Create Test POs";
                begin
                    CreateTestPOs.GenerateAndPostTestPOs();
                end;
            }
            action("Post Test POs")
            {
                ApplicationArea = All;
                Caption = 'Post Test POs';
                Image = PostedReceipt;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Find all Test POs and post their receipt and invoices.';

                trigger OnAction()
                var
                    CreateTestPOs: Codeunit "Create Test POs";
                begin
                    CreateTestPOs.PostTestPOs();
                end;
            }
        }
    }

}

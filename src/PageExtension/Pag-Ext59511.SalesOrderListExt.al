pageextension 59511 "SalesOrderList Ext" extends "Sales Order List"
{
    layout
    {
        addafter(Status)
        {
            field("Test Sales Order"; Rec."Test Sales Order")
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
            action("Generate Test Sales Orders")
            {
                ApplicationArea = All;
                Caption = 'Generate Test Sales Orders';
                Image = CreateBinContent;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Generate 100 test sales orders with random customers and items.';

                trigger OnAction()
                var
                    CreateTestSOs: Codeunit "Create Test SOs";
                begin
                    CreateTestSOs.GenerateTestSalesOrders();
                end;
            }
            // action("Generate and Post Test SOs")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Generate & Post Test SOs';
            //     Image = PostInventoryToGLTest;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     ToolTip = 'Will Generate 100 new random SOs, and post all existing Test SOs (Shipments and Invoices).';

            //     trigger OnAction()
            //     var
            //         CreateTestSOs: Codeunit "Create Test SOs";
            //     begin
            //         CreateTestSOs.GenerateAndPostTestSOs();
            //     end;
            // }
            action("Post Test SOs")
            {
                ApplicationArea = All;
                Caption = 'Post Test SOs';
                Image = PostedShipment;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Find all Test SOs and post their shipments and invoices.';

                trigger OnAction()
                var
                    CreateTestSOs: Codeunit "Create Test SOs";
                begin
                    CreateTestSOs.PostTestSOs();
                end;
            }
        }
    }
}
codeunit 59503 "Create Test SOs"
{
    var
        LocationCode: Code[10];

    local procedure GetLocationFromSetup(var ToLocationCode: Code[10])
    var
        InventorySetup: Record "Inventory Setup";
        Location: Record Location;
        LocationErr: Label 'Test Doc. Location must be set in Inventory Setup before generating test documents.';
        InvalidLocationErr: Label 'The location %1 specified in Inventory Setup is not a valid location code.', Comment = '%1 = Location Code';
    begin
        InventorySetup.Get();
        if InventorySetup."Test Doc. Location" = '' then
            Error(LocationErr);

        if not Location.Get(InventorySetup."Test Doc. Location") then
            Error(InvalidLocationErr, InventorySetup."Test Doc. Location");

        ToLocationCode := InventorySetup."Test Doc. Location";
    end;

    procedure GenerateAndPostTestSOs()
    begin
        //Step 1: Generate Sales Orders
        GenerateTestSalesOrders();

        //step 2: Update and post Sales Shipments
        PostAllTestShipments();

        //Step 3: Update and post Sales Invoices
        PostAllTestInvoices();
    end;

    procedure PostTestSOs()
    begin
        //Step 1: Update and post Sales Shipments
        PostAllTestShipments();

        //Step 2: Update and post Sales Invoices 
        PostAllTestInvoices();
    end;

    procedure GenerateTestSalesOrders()
    var
        CustomerRec: Record Customer;
        ItemRec: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TEMPItemBuffer: Record "Item Location Variant Buffer" temporary;
        CustomerList: List of [Code[20]];
        ItemList: List of [Code[20]];
        i, j, NumLines, Qty : Integer;
        CustomerCode: Code[20];
        NewLineNo: Integer;
        Window: Dialog;
    begin
        Window.Open('Collecting Data: #1###############\\' +
                   'Creating Order #2### of #3###\' +
                   'Adding Lines: #4### of #5###');

        // Step 1: Collect 4–5 random customers
        Window.Update(1, 'Collecting customers...');
        CustomerRec.Reset();
        CustomerRec.SetRange(Blocked, CustomerRec.Blocked::" ");
        CustomerRec.FindSet();
        while CustomerRec.Next() <> 0 do begin
            if CustomerList.Count < 5 then
                CustomerList.Add(CustomerRec."No.");
        end;

        // Step 2: Collect available items
        Window.Update(1, 'Collecting items...');
        ItemRec.Reset();
        ItemRec.SetRange("Blocked", false);
        ItemRec.SetRange(Type, ItemRec.Type::Inventory);
        ItemRec.SetFilter("Item Tracking Code", '=%1', '');
        ItemRec.FindSet();
        while ItemRec.Next() <> 0 do begin
            ItemList.Add(ItemRec."No.");
        end;

        // Step 3: Create 100 sales orders
        Window.Update(3, 100);
        for i := 1 to 100 do begin
            Window.Update(2, i);
            CustomerCode := CustomerList.Get((System.Random(CustomerList.Count())));
            Clear(SalesHeader);
            SalesHeader.Init();
            SalesHeader.validate("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.validate("Sell-to Customer No.", CustomerCode);
            SalesHeader.insert(true);
            GetLocationFromSetup(LocationCode);
            SalesHeader.Validate("Location Code", LocationCode);
            SalesHeader.validate("Test Sales Order", true);
            SalesHeader.validate("Shipment Date", WorkDate + (System.Random(30) + 1));
            SalesHeader.Modify(true);

            // Step 4: Add 1–7 item lines
            NewLineNo := 0;
            NumLines := System.Random(7) + 1;
            Window.Update(5, NumLines);
            for j := 1 to NumLines do begin
                Window.Update(4, j);
                NewLineNo += 10000;
                Clear(SalesLine);
                SalesLine.Init();
                SalesLine.validate("Document Type", SalesHeader."Document Type");
                SalesLine.validate("Document No.", SalesHeader."No.");
                SalesLine."Line No." := NewLineNo;
                SalesLine.Insert(true);
                SalesLine.validate(Type, SalesLine.Type::Item);
                SalesLine.validate("No.", ItemList.Get(System.Random(ItemList.Count)));
                SalesLine.validate("Location Code", SalesHeader."Location Code");
                SalesLine.validate(Quantity, System.Random(34) + 1);
                SalesLine.Modify(true);
                AddOrUpdateItemBuffer(SalesLine, TEMPItemBuffer);
            end;
        end;

        Window.Close();
        Message('100 Sales Orders have been created.');

        TEMPItemBuffer.Reset();
        if TEMPItemBuffer.FindSet() then begin
            repeat
                CreateTestItemQtyJnlLine(TEMPItemBuffer."Location Code", TEMPItemBuffer."Item No.", TEMPItemBuffer.Value1);
            until (TEMPItemBuffer.Next() = 0);
        end;

        Commit();

        PostNewItemJnlLines();
    end;

    local procedure AddOrUpdateItemBuffer(var SLine: Record "Sales Line"; var ItemBuffer: Record "Item Location Variant Buffer" temporary)
    begin
        AddOrUpdateItemBuffer(SLine."No.", SLine."Location Code", sline.Quantity, ItemBuffer);
    end;

    local procedure AddOrUpdateItemBuffer(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; var ItemBuffer: Record "Item Location Variant Buffer" temporary)
    begin
        if not ItemBuffer.get(ItemNo, '', LocationCode) then begin
            ItemBuffer.Init();
            ItemBuffer."Item No." := ItemNo;
            ItemBuffer."Variant Code" := '';
            ItemBuffer."Location Code" := LocationCode;
            ItemBuffer.Value1 := Qty;
            ItemBuffer.Insert();
        end else begin
            ItemBuffer.Value1 += Qty;
            ItemBuffer.Modify();
        end;
    end;

    local procedure PostAllTestShipments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        QuantityToHandle: Decimal;
        NeedsShipping: Boolean;
        Window: Dialog;
        TotalCount: Integer;
        CurrentCount: Integer;
    begin
        Window.Open('Posting Shipments: #1#### of #2####');

        // Get total count
        SalesHeader.SetRange("Test Sales Order", true);
        TotalCount := SalesHeader.Count;
        Window.Update(2, TotalCount);
        CurrentCount := 0;

        if SalesHeader.FindSet() then begin
            repeat
                NeedsShipping := false;

                SalesLine.Reset();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.SetRange(Type, SalesLine.Type::Item);
                if SalesLine.FindSet() then begin
                    repeat
                        QuantityToHandle := SalesLine.Quantity - SalesLine."Quantity Shipped";
                        if (QuantityToHandle > 0) then begin
                            SalesLine.Validate("Qty. to Ship", QuantityToHandle);
                            SalesLine.Modify(true);
                            NeedsShipping := true;
                        end;
                    until (SalesLine.Next() = 0);
                end;

                Commit();
                SalesHeader.Ship := true;
                SalesHeader.Invoice := false;
                if NeedsShipping then
                    if not SalesPost.Run(SalesHeader) then; //do nothing if posting fails
                CurrentCount += 1;
                Window.Update(1, CurrentCount);
            until (SalesHeader.Next() = 0);
        end;
        Window.Close();
    end;

    local procedure PostAllTestInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        QuantityToHandle: Decimal;
        NeedsInvoicing: Boolean;
        Window: Dialog;
        TotalCount: Integer;
        CurrentCount: Integer;
    begin
        Window.Open('Posting Invoices: #1#### of #2####');

        // Get total count
        SalesHeader.SetRange("Test Sales Order", true);
        TotalCount := SalesHeader.Count;
        Window.Update(2, TotalCount);
        CurrentCount := 0;

        if SalesHeader.FindSet() then begin
            repeat
                NeedsInvoicing := false;

                if SalesHeader."External Document No." = '' then begin
                    SalesHeader.Validate("External Document No.", 'INV' + Format(CurrentCount + 1, 0, '<Integer>'));
                    SalesHeader.Modify(true);
                end;

                SalesLine.Reset();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.SetRange(Type, SalesLine.Type::Item);
                if SalesLine.FindSet() then begin
                    repeat
                        QuantityToHandle := SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced";
                        if (QuantityToHandle > 0) then begin
                            SalesLine.Validate("Qty. to Invoice", QuantityToHandle);
                            SalesLine.Modify(true);
                            NeedsInvoicing := true;
                        end;
                    until (SalesLine.Next() = 0);
                end;

                SalesHeader2.GET(SalesHeader."Document Type", SalesHeader."No.");
                SalesHeader2.Ship := false;
                SalesHeader2.Invoice := true;

                Commit();
                if NeedsInvoicing then
                    if not SalesPost.Run(SalesHeader2) then; //do nothing if posting fails
                CurrentCount += 1;
                Window.Update(1, CurrentCount);
            until (SalesHeader.Next() = 0);
        end;
        Window.Close();
    end;

    local procedure CreateTestItemQtyJnlLine(LocationCode: Code[10]; ItemNo: Code[20]; QtyToPost: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        Item: Record Item;
        Location: Record Location;
        NoSetupErr: Label 'Test Data Item Journal Template and Batch must be set in Inventory Setup.';
        TemplateErr: Label 'Item Journal Template %1 does not exist.', Comment = '%1 = Template Code';
        BatchErr: Label 'Item Journal Batch %1 does not exist in Template %2.', Comment = '%1 = Batch Code, %2 = Template Code';
        ItemErr: Label 'Item %1 does not exist.', Comment = '%1 = Item No.';
        LocationErr: Label 'Location %1 does not exist.', Comment = '%1 = Location Code';
        QtyErr: Label 'Quantity to post must be greater than 0.';
        LastLineNo: Integer;
    begin
        // Validate parameters
        if QtyToPost <= 0 then
            Error(QtyErr);

        if not Item.Get(ItemNo) then
            Error(ItemErr, ItemNo);

        if not Location.Get(LocationCode) then
            Error(LocationErr, LocationCode);

        // Get and validate setup
        InventorySetup.Get();
        if (InventorySetup."Test Data Item Jnl. Template" = '') or
           (InventorySetup."Test Data Item Jnl. Batch" = '') then
            Error(NoSetupErr);

        if not ItemJnlTemplate.Get(InventorySetup."Test Data Item Jnl. Template") then
            Error(TemplateErr, InventorySetup."Test Data Item Jnl. Template");

        ItemJnlBatch.Reset();
        ItemJnlBatch.SetRange("Journal Template Name", InventorySetup."Test Data Item Jnl. Template");
        ItemJnlBatch.SetRange(Name, InventorySetup."Test Data Item Jnl. Batch");
        if not ItemJnlBatch.FindFirst() then
            Error(BatchErr, InventorySetup."Test Data Item Jnl. Batch",
                          InventorySetup."Test Data Item Jnl. Template");

        // Find next line number
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", InventorySetup."Test Data Item Jnl. Template");
        ItemJnlLine.SetRange("Journal Batch Name", InventorySetup."Test Data Item Jnl. Batch");
        if ItemJnlLine.FindLast() then
            LastLineNo := ItemJnlLine."Line No."
        else
            LastLineNo := 0;

        // Create and post the adjustment
        Clear(ItemJnlLine);
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", InventorySetup."Test Data Item Jnl. Template");
        ItemJnlLine.Validate("Journal Batch Name", InventorySetup."Test Data Item Jnl. Batch");
        ItemJnlLine."Line No." := LastLineNo + 10000;
        ItemJnlLine.Insert(true);

        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Document No.", Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate(Quantity, QtyToPost);
        ItemJnlLine.Modify(true);
    end;

    local procedure PostNewItemJnlLines()
    var
        InventorySetup: Record "Inventory Setup";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        NoSetupErr: Label 'Test Data Item Journal Template and Batch must be set in Inventory Setup.';
        TemplateErr: Label 'Item Journal Template %1 does not exist.', Comment = '%1 = Template Code';
        BatchErr: Label 'Item Journal Batch %1 does not exist in Template %2.', Comment = '%1 = Batch Code, %2 = Template Code';
        NoLinesErr: Label 'No lines found to post in Item Journal Batch %1.', Comment = '%1 = Batch Name';
        Window: Dialog;
        TotalLines: Integer;
        CurrentLine: Integer;
    begin
        // Get and validate setup
        InventorySetup.Get();
        if (InventorySetup."Test Data Item Jnl. Template" = '') or
           (InventorySetup."Test Data Item Jnl. Batch" = '') then
            Error(NoSetupErr);

        if not ItemJnlTemplate.Get(InventorySetup."Test Data Item Jnl. Template") then
            Error(TemplateErr, InventorySetup."Test Data Item Jnl. Template");

        ItemJnlBatch.Reset();
        ItemJnlBatch.SetRange("Journal Template Name", InventorySetup."Test Data Item Jnl. Template");
        ItemJnlBatch.SetRange(Name, InventorySetup."Test Data Item Jnl. Batch");
        if not ItemJnlBatch.FindFirst() then
            Error(BatchErr, InventorySetup."Test Data Item Jnl. Batch",
                          InventorySetup."Test Data Item Jnl. Template");

        // Find lines to post
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", InventorySetup."Test Data Item Jnl. Template");
        ItemJnlLine.SetRange("Journal Batch Name", InventorySetup."Test Data Item Jnl. Batch");
        TotalLines := ItemJnlLine.Count;

        if TotalLines = 0 then
            Error(NoLinesErr, InventorySetup."Test Data Item Jnl. Batch");

        // Show progress dialog
        Window.Open('Posting Item Journal Lines: #1#### of #2####');
        Window.Update(2, TotalLines);
        CurrentLine := 0;

        if ItemJnlLine.FindSet() then
            repeat
                CurrentLine += 1;
                Window.Update(1, CurrentLine);
                Codeunit.Run(Codeunit::"Item Jnl.-Post", ItemJnlLine);
            until ItemJnlLine.Next() = 0;

        Window.Close();
        Message('Successfully posted %1 item journal lines.', TotalLines);
    end;
}
codeunit 59500 "Create Test POs"
{
    procedure GenerateAndPostTestPOs()
    begin

        //Step 1: Generate Purchase Orders
        GenerateTestPurchaseOrders();

        //step 2: Update and post Purchase Receipts
        PostAllTestReceipts();

        //Step 3: Update and post Purchase Invoices
        PostAllTestInvoices();
    end;

    procedure PostTestPOs()
    begin
        //Step 1: Update and post Purchase Receipts
        PostAllTestReceipts();

        //Step 2: Update and post Purchase Invoices 
        PostAllTestInvoices();
    end;

    procedure GenerateTestPurchaseOrders()
    var
        VendorRec: Record Vendor;
        ItemRec: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VendorList: List of [Code[20]];
        ItemList: List of [Code[20]];
        i, j, NumLines, Qty : Integer;
        VendorCode: Code[20];
        NewLineNo: Integer;
        Window: Dialog;
    begin
        Window.Open('Collecting Data: #1###############\\' +
                   'Creating Order #2### of #3###\' +
                   'Adding Lines: #4### of #5###');
        // Step 1: Collect 4–5 random vendors
        Window.Update(1, 'Collecting vendors...');
        VendorRec.Reset();
        VendorRec.SetRange("Blocked", VendorRec.Blocked::" ");
        VendorRec.FindSet();
        while VendorRec.Next() <> 0 do begin
            if VendorList.Count < 5 then
                VendorList.Add(VendorRec."No.");
        end;

        // Step 2: Collect available items
        Window.Update(1, 'Collecting items...');
        ItemRec.Reset();
        ItemRec.SetRange("Blocked", false);
        ItemRec.SetRange(Type, ItemRec.Type::Inventory);
        itemrec.SetFilter("Item Tracking Code", '=%1', '');
        ItemRec.FindSet();
        while ItemRec.Next() <> 0 do begin
            ItemList.Add(ItemRec."No.");
        end;

        // Step 3: Create 100 purchase orders
        Window.Update(3, 100);
        for i := 1 to 100 do begin
            Window.Update(2, i);
            VendorCode := VendorList.Get((System.Random(VendorList.Count())));
            Clear(PurchHeader);
            PurchHeader.Init();
            PurchHeader.validate("Document Type", PurchHeader."Document Type"::Order);
            PurchHeader.validate("Buy-from Vendor No.", VendorCode);
            PurchHeader.validate("Location Code", 'BLUE');
            PurchHeader.validate("Test Purchase Order", true);
            PurchHeader.validate("Expected Receipt Date", WorkDate + (System.Random(30) + 1));
            PurchHeader.Insert(true);

            // Step 4: Add 1–7 item lines
            NewLineNo := 0;
            NumLines := System.Random(7) + 1;
            Window.Update(5, NumLines);
            for j := 1 to NumLines do begin
                Window.Update(4, j);
                NewLineNo += 10000;
                Clear(PurchLine);
                PurchLine.Init();
                PurchLine.validate("Document Type", PurchHeader."Document Type");
                PurchLine.validate("Document No.", PurchHeader."No.");
                PurchLine."Line No." := NewLineNo;
                PurchLine.Insert(true);
                PurchLine.validate(Type, PurchLine.Type::Item);
                PurchLine.validate("No.", ItemList.Get(System.Random(ItemList.Count)));
                PurchLine.validate(Quantity, System.Random(34) + 1);
                PurchLine.Modify(true);
            end;
        end;

        Window.Close();
        Message('100 Purchase Orders have been created.');
    end;

    local procedure PostAllTestReceipts()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        QuantityToHandle: Decimal;
        NeedsReceiving: Boolean;
        Window: Dialog;
        TotalCount: Integer;
        CurrentCount: Integer;
    begin
        Window.Open('Posting Receipts: #1#### of #2####');

        // Get total count
        PurchHeader.SetRange("Test Purchase Order", true);
        TotalCount := PurchHeader.Count;
        Window.Update(2, TotalCount);
        CurrentCount := 0;
        PurchHeader.SetRange("Test Purchase Order", true);
        if PurchHeader.FindSet() then begin
            repeat
                NeedsReceiving := false;

                PurchLine.Reset();
                purchline.SetRange("Document Type", PurchHeader."Document Type");
                purchline.SetRange("Document No.", PurchHeader."No.");
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                if PurchLine.FindSet() then begin
                    repeat
                        QuantityToHandle := PurchLine.Quantity - PurchLine."Quantity Received";
                        if (QuantityToHandle > 0) then begin
                            PurchLine.Validate("Qty. to Receive", QuantityToHandle);
                            PurchLine.Modify(true);
                            NeedsReceiving := true;
                        end;
                    until (PurchLine.Next() = 0);
                end;
                Commit();
                PurchHeader.Receive := true;
                PurchHeader.Invoice := false;
                if NeedsReceiving then
                    if not PurchPost.Run(PurchHeader) then; //do nothing if posting fails
                CurrentCount += 1;
                Window.Update(1, CurrentCount);
            until (PurchHeader.Next() = 0);
        end;
        Window.Close();
    end;

    local procedure PostAllTestInvoices()
    var
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        QuantityToHandle: Decimal;
        NeedsInvoicing: Boolean;
        Window: Dialog;
        TotalCount: Integer;
        CurrentCount: Integer;
    begin
        Window.Open('Posting Invoices: #1#### of #2####');

        // Get total count
        PurchHeader.SetRange("Test Purchase Order", true);
        TotalCount := PurchHeader.Count;
        Window.Update(2, TotalCount);
        CurrentCount := 0;
        PurchHeader.SetRange("Test Purchase Order", true);
        if PurchHeader.FindSet() then begin
            repeat
                NeedsInvoicing := false;

                if PurchHeader."Vendor Invoice No." = '' then begin
                    PurchHeader.Validate("Vendor Invoice No.", 'INV' + Format(CurrentCount + 1, 0, '<Integer>'));
                    PurchHeader.Modify(true);
                end;

                PurchLine.Reset();
                purchline.SetRange("Document Type", PurchHeader."Document Type");
                purchline.SetRange("Document No.", PurchHeader."No.");
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                if PurchLine.FindSet() then begin
                    repeat
                        QuantityToHandle := PurchLine."Quantity Received" - PurchLine."Quantity Invoiced";

                        if (QuantityToHandle > 0) then begin
                            PurchLine.Validate("Qty. to Invoice", QuantityToHandle);
                            PurchLine.Modify(true);
                            NeedsInvoicing := true;
                        end;
                    until (PurchLine.Next() = 0);
                end;

                PurchHeader2.GET(PurchHeader."Document Type", PurchHeader."No.");
                PurchHeader2.Receive := false;
                PurchHeader2.Invoice := true;

                Commit();
                if NeedsInvoicing then
                    if not PurchPost.Run(PurchHeader2) then; //do nothing if posting fails
                CurrentCount += 1;
                Window.Update(1, CurrentCount);
            until (PurchHeader.Next() = 0);
        end;
        Window.Close();
    end;

}

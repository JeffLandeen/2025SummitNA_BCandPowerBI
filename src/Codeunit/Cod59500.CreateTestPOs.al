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
    begin
        // Step 1: Collect 4–5 random vendors
        VendorRec.Reset();
        VendorRec.SetRange("Blocked", VendorRec.Blocked::" ");
        VendorRec.FindSet();
        while VendorRec.Next() <> 0 do begin
            if VendorList.Count < 5 then
                VendorList.Add(VendorRec."No.");
        end;

        // Step 2: Collect available items
        ItemRec.Reset();
        ItemRec.SetRange("Blocked", false);
        ItemRec.SetRange(Type, ItemRec.Type::Inventory);
        ItemRec.FindSet();
        while ItemRec.Next() <> 0 do begin
            ItemList.Add(ItemRec."No.");
        end;

        // Step 3: Create 100 purchase orders
        for i := 1 to 100 do begin
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
            for j := 1 to NumLines do begin
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

        Message('100 Purchase Orders have been created.');
    end;

    local procedure PostAllTestReceipts()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        QuantityToHandle: Decimal;
        NeedsReceiving: Boolean;
    begin
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
                        end;
                    until (PurchLine.Next() = 0);
                end;
                PurchHeader.Receive := true;
                PurchHeader.Invoice := false;
                PurchPost.Run(PurchHeader);
            until (PurchHeader.Next() = 0);
        end;
    end;

    local procedure PostAllTestInvoices()
    var
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        QuantityToHandle: Decimal;
        NeedsReceiving: Boolean;
    begin
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
                        QuantityToHandle := PurchLine.Quantity - PurchLine."Quantity Invoiced";
                        if (QuantityToHandle > 0) then begin
                            PurchLine.Validate("Qty. to Invoice", QuantityToHandle);
                            PurchLine.Modify(true);
                        end;
                    until (PurchLine.Next() = 0);
                end;

                PurchHeader2.GET(PurchHeader."Document Type", PurchHeader."No.");
                PurchHeader2.Receive := false;
                PurchHeader2.Invoice := true;
                PurchPost.Run(PurchHeader2);
            until (PurchHeader.Next() = 0);
        end;
    end;

}

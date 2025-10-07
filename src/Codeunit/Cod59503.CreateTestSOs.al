codeunit 59503 "Create Test SOs"
{
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
            SalesHeader.validate("Location Code", 'BLUE');
            SalesHeader.validate("Test Sales Order", true);
            SalesHeader.validate("Shipment Date", WorkDate + (System.Random(30) + 1));
            SalesHeader.Insert(true);

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
                SalesLine.validate(Quantity, System.Random(34) + 1);
                SalesLine.Modify(true);
            end;
        end;

        Window.Close();
        Message('100 Sales Orders have been created.');
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
}
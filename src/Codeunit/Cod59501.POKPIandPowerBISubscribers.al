codeunit 59501 "POKPIandPowerBI Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", OnAfterReleasePurchaseDoc, '', false, false)]
    local procedure "Release Purchase Document_OnAfterReleasePurchaseDoc"(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean; SkipWhseRequestOperations: Boolean)
    begin
        if (PurchaseHeader."Promised Receipt Date" <> 0D) and (PurchaseHeader."Target Receipt Date" = 0D) then begin
            PurchaseHeader.validate("Target Receipt Date", PurchaseHeader."Promised Receipt Date");
            PurchaseHeader.Modify(true);
        end else if (PurchaseHeader."Expected Receipt Date" <> 0D) and (PurchaseHeader."Target Receipt Date" = 0D) then begin
            PurchaseHeader.Validate("Target Receipt Date", PurchaseHeader."Expected Receipt Date");
            PurchaseHeader.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterInsertReceiptHeader, '', false, false)]
    local procedure "Purch.-Post_OnAfterInsertReceiptHeader"(var PurchHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
        if (PurchHeader."First Receipt Date" = 0D) and (PurchRcptHeader."Posting Date" <> 0D) then begin
            PurchHeader.Validate("First Receipt Date", PurchRcptHeader."Posting Date");
            PurchHeader.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforePostPurchaseDoc, '', false, false)]
    local procedure "Purch.-Post_OnBeforePostPurchaseDoc"(var Sender: Codeunit "Purch.-Post"; var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var IsHandled: Boolean)
    var
        LocalPurchLine: record "Purchase Line";
    begin
        if PurchaseHeader."Test Purchase Order" then begin
            LocalPurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
            LocalPurchLine.SetRange("Document No.", PurchaseHeader."No.");
            LocalPurchLine.ModifyAll("Test Purchase Order", PurchaseHeader."Test Purchase Order", true);
        end;
    end;
}

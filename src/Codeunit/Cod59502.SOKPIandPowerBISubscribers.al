codeunit 59502 "SOKPIandPowerBI Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", OnAfterReleaseSalesDoc, '', false, false)]
    local procedure "Release Sales Document_OnAfterReleaseSalesDoc"(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    begin
        if (SalesHeader."Promised Delivery Date" <> 0D) and (SalesHeader."Target Shipment Date" = 0D) then begin
            SalesHeader.validate("Target Shipment Date", SalesHeader."Promised Delivery Date");
            SalesHeader.Modify(true);
        end else if (SalesHeader."Shipment Date" <> 0D) and (SalesHeader."Target Shipment Date" = 0D) then begin
            SalesHeader.Validate("Target Shipment Date", SalesHeader."Shipment Date");
            SalesHeader.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterInsertShipmentHeader, '', false, false)]
    local procedure "Sales-Post_OnAfterInsertShipmentHeader"(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        if (SalesHeader."First Shipment Date" = 0D) and (SalesShipmentHeader."Posting Date" <> 0D) then begin
            SalesHeader.Validate("First Shipment Date", SalesShipmentHeader."Posting Date");
            SalesHeader.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforePostSalesDoc, '', false, false)]
    local procedure "Sales-Post_OnBeforePostSalesDoc"(var Sender: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean; var IsHandled: Boolean; var CalledBy: Integer)
    var
        LocalSalesLine: record "Sales Line";
    begin
        if SalesHeader."Test Sales Order" then begin
            LocalSalesLine.SetRange("Document Type", SalesHeader."Document Type");
            LocalSalesLine.SetRange("Document No.", SalesHeader."No.");
            LocalSalesLine.ModifyAll("Test Sales Order", SalesHeader."Test Sales Order", true);
        end;
    end;
}
codeunit 50199 "Safety Stock Demo Data"
{
    // SANDBOX UTILITY — generates unposted demo Sales and Purchase Orders
    // so the Safety Stock calculator has historical data to work with.
    // Do not run in production.

    Permissions = tabledata "Sales Header" = rim,
                  tabledata "Sales Line" = rim,
                  tabledata "Purchase Header" = rim,
                  tabledata "Purchase Line" = rim;

    procedure GenerateForItem(ItemNo: Code[20])
    var
        Item: Record Item;
        CustNo: Code[20];
        VendNo: Code[20];
        LocationCode: Code[10];
        i: Integer;
        OrderDate: Date;
        ReceiptDate: Date;
        PostingDate: Date;
        Qty: Decimal;
        EarliestDate: Date;
        PastSalesCount: Integer;
        PastPurchCount: Integer;
        FutureSalesCount: Integer;
        ResultTxt: Label 'Demo data created for item %1:\\Past Purchase Orders (post these FIRST to build inventory): %2\Past Sales Orders (post AFTER the POs to create demand history): %3\Future Sales Orders (leave unposted; for visual / MRP reference): %4\\Tip: open Sales Orders / Purchase Orders and use Post Batch.';
    begin
        if not Item.Get(ItemNo) then
            Error('Item %1 does not exist.', ItemNo);

        EarliestDate := CalcDate('<-180D>', Today);
        CheckPostingPeriodOpen(EarliestDate);

        CustNo := FindCustomer();
        VendNo := FindVendor();
        LocationCode := FindLocationForItem(Item);

        for i := 1 to 6 do begin
            OrderDate := CalcDate(StrSubstNo('<-%1D>', 30 + Random(150)), Today);
            ReceiptDate := CalcDate(StrSubstNo('<+%1D>', 6 + Random(15)), OrderDate);
            if ReceiptDate >= Today then
                ReceiptDate := CalcDate('<-1D>', Today);
            CreatePastPurchaseOrder(ItemNo, VendNo, LocationCode, OrderDate, ReceiptDate, 100);
            PastPurchCount += 1;
        end;

        for i := 1 to 30 do begin
            PostingDate := CalcDate(StrSubstNo('<-%1D>', 1 + Random(179)), Today);
            Qty := 1 + Random(14);
            CreatePastSalesOrder(ItemNo, CustNo, LocationCode, PostingDate, Qty);
            PastSalesCount += 1;
        end;

        for i := 1 to 3 do begin
            PostingDate := CalcDate(StrSubstNo('<+%1D>', 7 + Random(23)), Today);
            Qty := 1 + Random(19);
            CreateFutureSalesOrder(ItemNo, CustNo, LocationCode, PostingDate, Qty);
            FutureSalesCount += 1;
        end;

        Message(ResultTxt, ItemNo, PastPurchCount, PastSalesCount, FutureSalesCount);
    end;

    local procedure CheckPostingPeriodOpen(EarliestDate: Date)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if (GLSetup."Allow Posting From" <> 0D) and (EarliestDate < GLSetup."Allow Posting From") then
            Error('Allow Posting From in General Ledger Setup is %1, but demo data needs dates back to %2. Adjust GL Setup before continuing.', GLSetup."Allow Posting From", EarliestDate);
    end;

    local procedure FindCustomer(): Code[20]
    var
        Cust: Record Customer;
    begin
        Cust.SetRange(Blocked, Cust.Blocked::" ");
        if not Cust.FindFirst() then
            Error('No unblocked Customer found. Create one before running demo data generation.');
        exit(Cust."No.");
    end;

    local procedure FindVendor(): Code[20]
    var
        Vend: Record Vendor;
    begin
        Vend.SetRange(Blocked, Vend.Blocked::" ");
        if not Vend.FindFirst() then
            Error('No unblocked Vendor found. Create one before running demo data generation.');
        exit(Vend."No.");
    end;

    local procedure FindLocationForItem(Item: Record Item): Code[10]
    var
        Location: Record Location;
        InvSetup: Record "Inventory Setup";
    begin
        InvSetup.Get();
        if InvSetup."Location Mandatory" then begin
            Location.SetRange("Use As In-Transit", false);
            if Location.FindFirst() then
                exit(Location.Code);
        end;
        exit('');
    end;

    local procedure CreatePastSalesOrder(ItemNo: Code[20]; CustNo: Code[20]; LocationCode: Code[10]; PostingDate: Date; Qty: Decimal)
    var
        SH: Record "Sales Header";
        SL: Record "Sales Line";
    begin
        SH.Init();
        SH."Document Type" := SH."Document Type"::Order;
        SH.Insert(true);
        SH.Validate("Sell-to Customer No.", CustNo);
        SH.Validate("Posting Date", PostingDate);
        SH.Validate("Order Date", PostingDate);
        SH.Validate("Document Date", PostingDate);
        SH.Validate("Shipment Date", PostingDate);
        SH.Modify(true);

        SL.Init();
        SL."Document Type" := SH."Document Type";
        SL."Document No." := SH."No.";
        SL."Line No." := 10000;
        SL.Validate(Type, SL.Type::Item);
        SL.Validate("No.", ItemNo);
        if LocationCode <> '' then
            SL.Validate("Location Code", LocationCode);
        SL.Validate(Quantity, Qty);
        SL.Insert(true);
    end;

    local procedure CreateFutureSalesOrder(ItemNo: Code[20]; CustNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date; Qty: Decimal)
    var
        SH: Record "Sales Header";
        SL: Record "Sales Line";
    begin
        SH.Init();
        SH."Document Type" := SH."Document Type"::Order;
        SH.Insert(true);
        SH.Validate("Sell-to Customer No.", CustNo);
        SH.Validate("Order Date", Today);
        SH.Validate("Document Date", Today);
        SH.Validate("Shipment Date", ShipmentDate);
        SH.Modify(true);

        SL.Init();
        SL."Document Type" := SH."Document Type";
        SL."Document No." := SH."No.";
        SL."Line No." := 10000;
        SL.Validate(Type, SL.Type::Item);
        SL.Validate("No.", ItemNo);
        if LocationCode <> '' then
            SL.Validate("Location Code", LocationCode);
        SL.Validate(Quantity, Qty);
        SL.Validate("Shipment Date", ShipmentDate);
        SL.Insert(true);
    end;

    local procedure CreatePastPurchaseOrder(ItemNo: Code[20]; VendNo: Code[20]; LocationCode: Code[10]; OrderDate: Date; ReceiptDate: Date; Qty: Decimal)
    var
        PH: Record "Purchase Header";
        PL: Record "Purchase Line";
    begin
        PH.Init();
        PH."Document Type" := PH."Document Type"::Order;
        PH.Insert(true);
        PH.Validate("Buy-from Vendor No.", VendNo);
        PH.Validate("Order Date", OrderDate);
        PH.Validate("Posting Date", ReceiptDate);
        PH.Validate("Document Date", OrderDate);
        PH.Modify(true);

        PL.Init();
        PL."Document Type" := PH."Document Type";
        PL."Document No." := PH."No.";
        PL."Line No." := 10000;
        PL.Validate(Type, PL.Type::Item);
        PL.Validate("No.", ItemNo);
        if LocationCode <> '' then
            PL.Validate("Location Code", LocationCode);
        PL.Validate(Quantity, Qty);
        PL.Validate("Expected Receipt Date", ReceiptDate);
        PL.Insert(true);
    end;
}

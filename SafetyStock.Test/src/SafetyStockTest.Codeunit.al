/// <summary>
/// Tests for the BC Safety Stock Calculator ("Safety Stock Calculator" codeunit).
/// </summary>
codeunit 59100 "Safety Stock Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure ReturnsItemBlockedForBlockedItem()
    var
        Item: Record Item;
        Calc: Codeunit "Safety Stock Calculator";
        ResultCode: Enum "Safety Stock Result Code";
        Note: Text[250];
        Result: Decimal;
    begin
        // [GIVEN] A blocked item
        CreateItem(Item);
        Item.Blocked := true;
        Item.Modify();

        // [WHEN] Calculating safety stock
        Result := Calc.CalculateForItem(Item."No.", 95, false, ResultCode, Note);

        // [THEN] It is skipped with the Item Blocked result code
        LibraryAssert.AreEqual(ResultCode::"Item Blocked", ResultCode, 'Blocked item should yield Item Blocked');
        LibraryAssert.AreEqual(0, Result, 'Blocked item should return 0');
    end;

    [Test]
    procedure ReturnsInsufficientDataWithoutDemand()
    var
        Item: Record Item;
        Calc: Codeunit "Safety Stock Calculator";
        ResultCode: Enum "Safety Stock Result Code";
        Note: Text[250];
    begin
        // [GIVEN] An item with no sales history
        CreateItem(Item);

        // [WHEN] Calculating safety stock
        Calc.CalculateForItem(Item."No.", 95, false, ResultCode, Note);

        // [THEN] It is skipped due to insufficient demand data
        LibraryAssert.AreEqual(ResultCode::"Insufficient Demand Data", ResultCode, 'No demand should yield Insufficient Demand Data');
    end;

    [Test]
    procedure CalculatesPositiveSafetyStockForVaryingDemand()
    var
        Item: Record Item;
        Setup: Record "Safety Stock Setup";
        Calc: Codeunit "Safety Stock Calculator";
        ResultCode: Enum "Safety Stock Result Code";
        Note: Text[250];
        Result: Decimal;
    begin
        // [GIVEN] Setup that accepts 2 observations, an item with a lead time and varying daily demand
        Setup.GetSetup();
        Setup."Min Demand Observations" := 2;
        Setup.Modify();

        CreateItem(Item);
        Evaluate(Item."Lead Time Calculation", '<7D>');
        Item.Modify();
        CreateSale(Item."No.", CalcDate('<-5D>', Today), 10);
        CreateSale(Item."No.", CalcDate('<-10D>', Today), 4);

        // [WHEN] Calculating safety stock (without applying)
        Result := Calc.CalculateForItem(Item."No.", 95, false, ResultCode, Note);

        // [THEN] A positive buffer is produced
        LibraryAssert.AreEqual(ResultCode::OK, ResultCode, 'Varying demand with lead time should succeed');
        LibraryAssert.IsTrue(Result > 0, 'Safety stock should be greater than zero for varying demand');
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := CopyStr('SSTEST-' + Format(Random(999999)), 1, MaxStrLen(Item."No."));
        Item.Type := Item.Type::Inventory;
        Item."Replenishment System" := Item."Replenishment System"::Purchase;
        Item.Insert(true);
    end;

    local procedure CreateSale(ItemNo: Code[20]; PostingDate: Date; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LastEntry: Record "Item Ledger Entry";
        NextEntryNo: Integer;
    begin
        if LastEntry.FindLast() then
            NextEntryNo := LastEntry."Entry No." + 1
        else
            NextEntryNo := 1;
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := NextEntryNo;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Sale;
        ItemLedgerEntry.Quantity := -Qty; // sales post as negative quantity
        ItemLedgerEntry.Insert(false);
    end;
}

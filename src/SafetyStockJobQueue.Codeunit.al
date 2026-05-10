codeunit 50101 "Safety Stock Job Queue Run"
{
    // Schedule via: Job Queue Entry -> Object Type to Run: Codeunit -> Object ID: 50101
    // The Job Queue Entry record can carry a Parameter String like "FILTER=Item Category:FERT;SERVICELEVEL=99"
    // Without parameters, all inventory items at the setup default service level are processed.

    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        Item: Record Item;
        Setup: Record "Safety Stock Setup";
        Calc: Codeunit "Safety Stock Calculator";
        Params: Text;
        FilterClause: Text;
        SLText: Text;
        ServiceLevel: Decimal;
    begin
        Setup.GetSetup();
        Params := Rec."Parameter String";
        ServiceLevel := Setup."Default Service Level %";

        FilterClause := GetParam(Params, 'FILTER');
        SLText := GetParam(Params, 'SERVICELEVEL');
        if SLText <> '' then
            Evaluate(ServiceLevel, SLText);

        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange(Blocked, false);

        if FilterClause <> '' then
            ApplySimpleFilter(Item, FilterClause);

        Calc.CalculateBulk(Item, ServiceLevel, true);
    end;

    local procedure GetParam(Params: Text; Key: Text): Text
    var
        i: Integer;
        Segments: List of [Text];
        Segment: Text;
        KvSplit: Integer;
        ThisKey: Text;
    begin
        Segments := Params.Split(';');
        foreach Segment in Segments do begin
            KvSplit := StrPos(Segment, '=');
            if KvSplit > 0 then begin
                ThisKey := CopyStr(Segment, 1, KvSplit - 1).Trim();
                if UpperCase(ThisKey) = UpperCase(Key) then
                    exit(CopyStr(Segment, KvSplit + 1).Trim());
            end;
        end;
        exit('');
    end;

    local procedure ApplySimpleFilter(var Item: Record Item; Clause: Text)
    var
        ColonIdx: Integer;
        FieldName: Text;
        FieldValue: Text;
    begin
        // Format expected: "FieldName:Value" (e.g. "Item Category Code:FERT")
        ColonIdx := StrPos(Clause, ':');
        if ColonIdx = 0 then
            exit;
        FieldName := CopyStr(Clause, 1, ColonIdx - 1).Trim();
        FieldValue := CopyStr(Clause, ColonIdx + 1).Trim();
        if FieldValue = '' then
            exit;

        case UpperCase(FieldName) of
            'ITEM CATEGORY CODE', 'ITEMCATEGORY':
                Item.SetFilter("Item Category Code", FieldValue);
            'INVENTORY POSTING GROUP', 'POSTINGGROUP':
                Item.SetFilter("Inventory Posting Group", FieldValue);
            'VENDOR NO.', 'VENDORNO':
                Item.SetFilter("Vendor No.", FieldValue);
            'NO.', 'ITEMNO':
                Item.SetFilter("No.", FieldValue);
        end;
    end;
}

codeunit 50100 "Safety Stock Calculator"
{
    Permissions = tabledata Item = rm,
                  tabledata "Safety Stock Calculation Log" = ri;

    var
        Setup: Record "Safety Stock Setup";
        SetupLoaded: Boolean;

    /// <summary>
    /// Calculates and (optionally) updates Safety Stock for a single item.
    /// Returns the calculated safety stock quantity. Logs to history if enabled.
    /// </summary>
    procedure CalculateForItem(ItemNo: Code[20]; ServiceLevelPct: Decimal; Apply: Boolean): Decimal
    var
        Item: Record Item;
        LogEntry: Record "Safety Stock Calculation Log";
        AvgDemand: Decimal;
        DemandStdDev: Decimal;
        AvgLeadTime: Decimal;
        LeadTimeStdDev: Decimal;
        Observations: Integer;
        ZScore: Decimal;
        SafetyStock: Decimal;
        PreviousSS: Decimal;
        ResultCode: Enum "Safety Stock Result Code";
        Note: Text[250];
    begin
        EnsureSetup();
        if not Item.Get(ItemNo) then
            exit(0);

        if Item.Blocked then begin
            ResultCode := ResultCode::"Item Blocked";
            Note := 'Item is blocked.';
            LogResult(Item."No.", ServiceLevelPct, 0, 0, 0, 0, 0, 0, 0, Item."Safety Stock Quantity", ResultCode, Note);
            exit(0);
        end;

        ComputeDemandStats(ItemNo, AvgDemand, DemandStdDev, Observations);
        if Observations < Setup."Min Demand Observations" then begin
            ResultCode := ResultCode::"Insufficient Demand Data";
            Note := StrSubstNo('Only %1 demand observations found (minimum %2).', Observations, Setup."Min Demand Observations");
            LogResult(Item."No.", ServiceLevelPct, 0, AvgDemand, DemandStdDev, 0, 0, Observations, 0, Item."Safety Stock Quantity", ResultCode, Note);
            exit(0);
        end;

        ComputeLeadTimeStats(ItemNo, AvgLeadTime, LeadTimeStdDev);
        if AvgLeadTime <= 0 then begin
            // Fall back to vendor lead time on item if available
            AvgLeadTime := DaysFromDateFormula(Item."Lead Time Calculation");
            LeadTimeStdDev := 0;
        end;

        if AvgLeadTime <= 0 then begin
            ResultCode := ResultCode::"No Lead Time Data";
            Note := 'No historical lead time and no Lead Time Calculation on item.';
            LogResult(Item."No.", ServiceLevelPct, 0, AvgDemand, DemandStdDev, 0, 0, Observations, 0, Item."Safety Stock Quantity", ResultCode, Note);
            exit(0);
        end;

        ZScore := GetZScore(ServiceLevelPct);
        SafetyStock := ZScore * Sqrt(
            (AvgLeadTime * Power(DemandStdDev, 2)) +
            (Power(AvgDemand, 2) * Power(LeadTimeStdDev, 2))
        );

        if Setup."Round Up Result" then
            SafetyStock := Round(SafetyStock, 1, '>');

        PreviousSS := Item."Safety Stock Quantity";

        if Apply and Setup."Update Item Field" then begin
            Item.Validate("Safety Stock Quantity", SafetyStock);
            Item.Modify(true);
        end;

        ResultCode := ResultCode::OK;
        Note := StrSubstNo('Z=%1; LT=%2 d (σ=%3); D=%4/d (σ=%5); n=%6 obs.',
            Format(Round(ZScore, 0.0001), 0, 9), Format(Round(AvgLeadTime, 0.01), 0, 9),
            Format(Round(LeadTimeStdDev, 0.01), 0, 9), Format(Round(AvgDemand, 0.01), 0, 9),
            Format(Round(DemandStdDev, 0.01), 0, 9), Observations);

        LogResult(Item."No.", ServiceLevelPct, ZScore, AvgDemand, DemandStdDev, AvgLeadTime, LeadTimeStdDev, Observations, SafetyStock, PreviousSS, ResultCode, Note);

        exit(SafetyStock);
    end;

    /// <summary>
    /// Bulk calculation for items currently filtered on the Item record passed in.
    /// </summary>
    procedure CalculateBulk(var ItemFilter: Record Item; ServiceLevelPct: Decimal; Apply: Boolean): Integer
    var
        Item: Record Item;
        ProcessedCount: Integer;
        Window: Dialog;
        Total: Integer;
        Done: Integer;
    begin
        EnsureSetup();
        if ServiceLevelPct = 0 then
            ServiceLevelPct := Setup."Default Service Level %";

        Item.CopyFilters(ItemFilter);
        Item.SetRange(Type, Item.Type::Inventory);
        Total := Item.Count();
        if Total = 0 then
            exit(0);

        Window.Open('Calculating Safety Stock...\#1######### / #2#########');
        Window.Update(2, Format(Total));

        if Item.FindSet() then
            repeat
                Done += 1;
                Window.Update(1, Format(Done));
                CalculateForItem(Item."No.", ServiceLevelPct, Apply);
                ProcessedCount += 1;
            until Item.Next() = 0;

        Window.Close();
        exit(ProcessedCount);
    end;

    local procedure EnsureSetup()
    begin
        if not SetupLoaded then begin
            Setup.GetSetup();
            SetupLoaded := true;
        end;
    end;

    local procedure ComputeDemandStats(ItemNo: Code[20]; var AvgDemand: Decimal; var StdDev: Decimal; var Observations: Integer)
    var
        ILE: Record "Item Ledger Entry";
        DailyDemand: Dictionary of [Date, Decimal];
        Sum_Qty: Decimal;
        SumSq_Qty: Decimal;
        d: Date;
        qty: Decimal;
        WindowStart: Date;
        n: Integer;
        Mean: Decimal;
        Variance: Decimal;
    begin
        AvgDemand := 0;
        StdDev := 0;
        Observations := 0;

        WindowStart := CalcDate(StrSubstNo('<-%1D>', Setup."History Window (Days)"), Today);

        ILE.SetCurrentKey("Item No.", "Posting Date");
        ILE.SetRange("Item No.", ItemNo);
        ILE.SetRange("Posting Date", WindowStart, Today);
        ILE.SetRange("Entry Type", ILE."Entry Type"::Sale);
        if not ILE.FindSet() then
            exit;

        // Aggregate by date (signed quantity is negative for sales -> flip to positive demand)
        repeat
            qty := -ILE.Quantity;
            if qty > 0 then begin
                if DailyDemand.ContainsKey(ILE."Posting Date") then
                    DailyDemand.Set(ILE."Posting Date", DailyDemand.Get(ILE."Posting Date") + qty)
                else
                    DailyDemand.Add(ILE."Posting Date", qty);
            end;
        until ILE.Next() = 0;

        n := DailyDemand.Count;
        if n = 0 then
            exit;

        foreach d in DailyDemand.Keys do begin
            qty := DailyDemand.Get(d);
            Sum_Qty += qty;
            SumSq_Qty += qty * qty;
        end;

        Mean := Sum_Qty / n;
        if n > 1 then
            Variance := (SumSq_Qty - n * Mean * Mean) / (n - 1)
        else
            Variance := 0;

        if Variance < 0 then Variance := 0;

        AvgDemand := Mean;
        StdDev := Sqrt(Variance);
        Observations := n;
    end;

    local procedure ComputeLeadTimeStats(ItemNo: Code[20]; var AvgLT: Decimal; var StdDev: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchHeader: Record "Purchase Header";
        Sum_LT: Decimal;
        SumSq_LT: Decimal;
        n: Integer;
        LTDays: Decimal;
        Mean: Decimal;
        Variance: Decimal;
    begin
        AvgLT := 0;
        StdDev := 0;

        PurchRcptLine.SetCurrentKey("No.");
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        if not PurchRcptLine.FindSet() then
            exit;

        repeat
            if (PurchRcptLine."Order Date" <> 0D) and (PurchRcptLine."Posting Date" <> 0D) then begin
                LTDays := PurchRcptLine."Posting Date" - PurchRcptLine."Order Date";
                if LTDays >= 0 then begin
                    Sum_LT += LTDays;
                    SumSq_LT += LTDays * LTDays;
                    n += 1;
                end;
            end;
        until PurchRcptLine.Next() = 0;

        if n = 0 then
            exit;

        Mean := Sum_LT / n;
        if n > 1 then
            Variance := (SumSq_LT - n * Mean * Mean) / (n - 1)
        else
            Variance := 0;
        if Variance < 0 then Variance := 0;

        AvgLT := Mean;
        StdDev := Sqrt(Variance);
    end;

    local procedure GetZScore(ServiceLevelPct: Decimal): Decimal
    begin
        // Approximation table for common service levels.
        // For arbitrary values, falls back to closest match.
        case true of
            ServiceLevelPct >= 99.99: exit(3.7190);
            ServiceLevelPct >= 99.90: exit(3.0902);
            ServiceLevelPct >= 99.50: exit(2.5758);
            ServiceLevelPct >= 99.00: exit(2.3263);
            ServiceLevelPct >= 98.00: exit(2.0537);
            ServiceLevelPct >= 97.50: exit(1.9600);
            ServiceLevelPct >= 97.00: exit(1.8808);
            ServiceLevelPct >= 96.00: exit(1.7507);
            ServiceLevelPct >= 95.00: exit(1.6449);
            ServiceLevelPct >= 90.00: exit(1.2816);
            ServiceLevelPct >= 85.00: exit(1.0364);
            ServiceLevelPct >= 80.00: exit(0.8416);
            ServiceLevelPct >= 75.00: exit(0.6745);
            else
                exit(0.5244); // 70%
        end;
    end;

    local procedure DaysFromDateFormula(DF: DateFormula): Decimal
    var
        Today2: Date;
        ResultDate: Date;
    begin
        if Format(DF) = '' then
            exit(0);
        Today2 := Today;
        ResultDate := CalcDate(DF, Today2);
        exit(ResultDate - Today2);
    end;

    local procedure LogResult(ItemNo: Code[20]; SLPct: Decimal; Z: Decimal; AvgD: Decimal; SDD: Decimal; AvgLT: Decimal; SDL: Decimal; Obs: Integer; Result: Decimal; PrevResult: Decimal; ResultCode: Enum "Safety Stock Result Code"; Note: Text[250])
    var
        LogEntry: Record "Safety Stock Calculation Log";
    begin
        EnsureSetup();
        if not Setup."Log History" then
            exit;
        LogEntry.Init();
        LogEntry."Item No." := ItemNo;
        LogEntry."Calculation DateTime" := CurrentDateTime;
        LogEntry."User ID" := CopyStr(UserId, 1, MaxStrLen(LogEntry."User ID"));
        LogEntry."Service Level %" := SLPct;
        LogEntry."Z-Score" := Z;
        LogEntry."Avg Daily Demand" := AvgD;
        LogEntry."Demand StdDev" := SDD;
        LogEntry."Lead Time (Days)" := AvgLT;
        LogEntry."Lead Time StdDev" := SDL;
        LogEntry."Demand Observations" := Obs;
        LogEntry."Calculated Safety Stock" := Result;
        LogEntry."Previous Safety Stock" := PrevResult;
        LogEntry."Result Code" := ResultCode;
        LogEntry.Note := Note;
        LogEntry.Insert(true);
    end;
}

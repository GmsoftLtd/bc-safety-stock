pageextension 50101 "Item List SS Ext" extends "Item List"
{
    actions
    {
        addlast(Promoted)
        {
            actionref(CalcSafetyStockBulk_Promoted; CalcSafetyStockBulk)
            {
            }
        }
        addafter("Stockkeepin&g Units")
        {
            action(CalcSafetyStockBulk)
            {
                Caption = 'Calculate Safety Stock (Bulk, Sales-Based)';
                ApplicationArea = All;
                Image = CalculateLines;
                ToolTip = 'Run the Safety Stock calculation for items currently filtered or selected. Uses historical SALES and PURCHASE RECEIPTS with the Z-score method. Intended for purchased-and-resold items. Manufactured items, sub-assemblies, and BOM components will typically return 0 because consumption and production entries are not counted.';

                trigger OnAction()
                var
                    Item: Record Item;
                    Setup: Record "Safety Stock Setup";
                    Calc: Codeunit "Safety Stock Calculator";
                    Processed: Integer;
                    NonPurchaseCount: Integer;
                    Confirmed: Boolean;
                    ConfirmTxt: Label 'Calculate Safety Stock for items matching the current filters and apply the result?\Service level: %1%.\\This tool is sales-based; %2 of the selected items are not Purchase-replenished and will likely return 0.\\Continue?';
                    ConfirmPurchaseOnlyTxt: Label 'Calculate Safety Stock for items matching the current filters and apply the result?\Service level: %1%.';
                begin
                    Setup.GetSetup();

                    CurrPage.SetSelectionFilter(Item);
                    if Item.IsEmpty then
                        Item.CopyFilters(Rec);

                    NonPurchaseCount := CountNonPurchase(Item);
                    if NonPurchaseCount > 0 then
                        Confirmed := Confirm(ConfirmTxt, false, Format(Setup."Default Service Level %"), NonPurchaseCount)
                    else
                        Confirmed := Confirm(ConfirmPurchaseOnlyTxt, false, Format(Setup."Default Service Level %"));
                    if not Confirmed then
                        exit;

                    Processed := Calc.CalculateBulk(Item, Setup."Default Service Level %", true);
                    Message('Calculated Safety Stock for %1 item(s). See Safety Stock Calculation Log for details.', Processed);
                end;
            }
        }
    }

    local procedure CountNonPurchase(var ItemFilter: Record Item): Integer
    var
        Item: Record Item;
        Count: Integer;
    begin
        Item.CopyFilters(ItemFilter);
        Item.SetFilter("Replenishment System", '<>%1', Item."Replenishment System"::Purchase);
        Count := Item.Count();
        exit(Count);
    end;
}

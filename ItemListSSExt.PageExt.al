pageextension 50101 "Item List SS Ext" extends "Item List"
{
    actions
    {
        addlast(Promoted)
        {
            group(SafetyStockBulkGroup)
            {
                Caption = 'Safety Stock';

                actionref(CalcSafetyStockBulk_Promoted; CalcSafetyStockBulk)
                {
                }
            }
        }
        addlast("F&unctions")
        {
            action(CalcSafetyStockBulk)
            {
                Caption = 'Calculate Safety Stock (Bulk)';
                ApplicationArea = All;
                Image = CalculateLines;
                ToolTip = 'Run the Safety Stock calculation for items currently filtered or selected on the list. Uses the Z-score method on historical demand and lead times.';

                trigger OnAction()
                var
                    Item: Record Item;
                    Setup: Record "Safety Stock Setup";
                    Calc: Codeunit "Safety Stock Calculator";
                    Processed: Integer;
                    Confirmed: Boolean;
                    ConfirmTxt: Label 'Calculate Safety Stock for items matching the current filters and apply the result?\\Service level: %1%.';
                begin
                    Setup.GetSetup();
                    Confirmed := Confirm(ConfirmTxt, false, Format(Setup."Default Service Level %"));
                    if not Confirmed then
                        exit;

                    CurrPage.SetSelectionFilter(Item);
                    if Item.IsEmpty then
                        Item.CopyFilters(Rec);

                    Processed := Calc.CalculateBulk(Item, Setup."Default Service Level %", true);
                    Message('Calculated Safety Stock for %1 item(s). See Safety Stock Calculation Log for details.', Processed);
                end;
            }
        }
    }
}

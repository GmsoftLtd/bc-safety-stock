pageextension 50100 "Item Card SS Ext" extends "Item Card"
{
    actions
    {
        addlast(Promoted)
        {
            group(SafetyStockGroup)
            {
                Caption = 'Safety Stock';

                actionref(CalcSafetyStock_Promoted; CalcSafetyStock)
                {
                }
            }
        }
        addafter("Stockkeepin&g Units")
        {
            action(CalcSafetyStock)
            {
                Caption = 'Calculate Safety Stock';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Compute Safety Stock for this item based on historical demand and lead time variability using the Z-score method.';

                trigger OnAction()
                var
                    Setup: Record "Safety Stock Setup";
                    Calc: Codeunit "Safety Stock Calculator";
                    ServiceLevel: Decimal;
                    Result: Decimal;
                    ApplyResult: Boolean;
                    MsgTxt: Label 'Safety Stock for %1: %2 units.\Previous value: %3.\\Apply this value to the item?';
                    MsgPreviewTxt: Label 'Safety Stock for %1 would be: %2 units (preview only).\Previous value: %3.';
                begin
                    Setup.GetSetup();
                    ServiceLevel := Setup."Default Service Level %";

                    Result := Calc.CalculateForItem(Rec."No.", ServiceLevel, false);

                    if Setup."Update Item Field" then begin
                        ApplyResult := Confirm(MsgTxt, true, Rec."No.", Format(Result), Format(Rec."Safety Stock Quantity"));
                        if ApplyResult then
                            Calc.CalculateForItem(Rec."No.", ServiceLevel, true);
                    end else
                        Message(MsgPreviewTxt, Rec."No.", Format(Result), Format(Rec."Safety Stock Quantity"));

                    CurrPage.Update(true);
                end;
            }
        }
    }
}

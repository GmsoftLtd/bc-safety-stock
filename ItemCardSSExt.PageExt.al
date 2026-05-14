pageextension 50100 "Item Card SS Ext" extends "Item Card"
{
    actions
    {
        addlast(Promoted)
        {
            actionref(CalcSafetyStock_Promoted; CalcSafetyStock)
            {
            }
        }
        addafter("Stockkeepin&g Units")
        {
            action(CalcSafetyStock)
            {
                Caption = 'Calculate Safety Stock (Sales-Based)';
                ApplicationArea = All;
                Image = Calculate;
                ToolTip = 'Compute Safety Stock for this item from historical SALES and PURCHASE RECEIPTS using the Z-score method. Intended for purchased-and-resold items. Not suitable for manufactured items, sub-assemblies, or BOM components — those are consumed (not sold) and produced (not received), so the calculation will return 0.';

                trigger OnAction()
                var
                    Setup: Record "Safety Stock Setup";
                    Calc: Codeunit "Safety Stock Calculator";
                    ResultCode: Enum "Safety Stock Result Code";
                    Note: Text[250];
                    ServiceLevel: Decimal;
                    Result: Decimal;
                    ApplyResult: Boolean;
                    Warning: Text;
                    Details: Text;
                    MsgTxt: Label '%1Safety Stock for %2: %3 units.\Previous value: %4.\Result: %5%6\\Apply this value to the item?';
                    MsgPreviewTxt: Label '%1Safety Stock for %2 would be: %3 units (preview only).\Previous value: %4.\Result: %5%6';
                    NotPurchasedTxt: Label 'Warning: this item is set to %1 replenishment. This tool uses historical sales/purchases only and is intended for purchased-and-resold items. Result may not be meaningful for produced or assembled items.\\';
                begin
                    Setup.GetSetup();
                    ServiceLevel := Setup."Default Service Level %";

                    if Rec."Replenishment System" <> Rec."Replenishment System"::Purchase then
                        Warning := StrSubstNo(NotPurchasedTxt, Format(Rec."Replenishment System"));

                    Result := Calc.CalculateForItem(Rec."No.", ServiceLevel, false, ResultCode, Note);
                    if Note <> '' then
                        Details := '\' + Note;

                    if Setup."Update Item Field" then begin
                        ApplyResult := Confirm(MsgTxt, true, Warning, Rec."No.", Format(Result), Format(Rec."Safety Stock Quantity"), Format(ResultCode), Details);
                        if ApplyResult then
                            Calc.CalculateForItem(Rec."No.", ServiceLevel, true);
                    end else
                        Message(MsgPreviewTxt, Warning, Rec."No.", Format(Result), Format(Rec."Safety Stock Quantity"), Format(ResultCode), Details);

                    CurrPage.Update(true);
                end;
            }
            action(ShowSSLog)
            {
                Caption = 'Safety Stock Log';
                ApplicationArea = All;
                Image = Log;
                ToolTip = 'Show the Safety Stock Calculation Log entries for this item.';

                trigger OnAction()
                var
                    LogEntry: Record "Safety Stock Calculation Log";
                    LogPage: Page "Safety Stock Calculation Log";
                begin
                    LogEntry.SetRange("Item No.", Rec."No.");
                    LogPage.SetTableView(LogEntry);
                    LogPage.Run();
                end;
            }
            action(GenerateSSDemoData)
            {
                Caption = 'Generate Demo Data (Sandbox)';
                ApplicationArea = All;
                Image = TestFile;
                ToolTip = 'SANDBOX ONLY. Creates ~6 past Purchase Orders and ~30 past Sales Orders (last 180 days) plus 3 future Sales Orders, all linked to this item and unposted. Post the Purchase Orders first, then the Sales Orders, then run Calculate Safety Stock to see real numbers. Do not run in production.';

                trigger OnAction()
                var
                    Demo: Codeunit "Safety Stock Demo Data";
                    ConfirmTxt: Label 'SANDBOX UTILITY\\This will create approximately:\  - 6 unposted Purchase Orders dated in the last 180 days\  - 30 unposted Sales Orders dated in the last 180 days\  - 3 unposted Sales Orders dated 1-4 weeks ahead\\All linked to item %1. Post the Purchase Orders first, then the Sales Orders, then re-run Calculate Safety Stock.\\Continue?';
                begin
                    if not Confirm(ConfirmTxt, false, Rec."No.") then
                        exit;
                    Demo.GenerateForItem(Rec."No.");
                end;
            }
        }
    }
}

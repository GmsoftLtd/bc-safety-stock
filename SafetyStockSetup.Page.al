page 50100 "Safety Stock Setup"
{
    Caption = 'Safety Stock Setup';
    PageType = Card;
    SourceTable = "Safety Stock Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Defaults)
            {
                Caption = 'Calculation Defaults';

                field("Default Service Level %"; Rec."Default Service Level %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default target fill rate for new items. 95% means accepting roughly one stockout in twenty replenishment cycles. Higher = more stock, fewer stockouts.';
                }
                field("History Window (Days)"; Rec."History Window (Days)")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many days of history (backwards from today) to use for the demand sample. 180 days is a balanced default.';
                }
                field("Min Demand Observations"; Rec."Min Demand Observations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Minimum number of non-zero demand entries needed to calculate. Below this, the item is skipped (insufficient data).';
                }
            }
            group(Behaviour)
            {
                Caption = 'Behaviour';

                field("Round Up Result"; Rec."Round Up Result")
                {
                    ApplicationArea = All;
                    ToolTip = 'Round computed safety stock up to the next whole unit. Recommended for items measured in whole pieces.';
                }
                field("Update Item Field"; Rec."Update Item Field")
                {
                    ApplicationArea = All;
                    ToolTip = 'Write the result directly to Item."Safety Stock Quantity". Disable to preview calculations only.';
                }
                field("Log History"; Rec."Log History")
                {
                    ApplicationArea = All;
                    ToolTip = 'Save each calculation to a history log for traceability and audit.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenLog)
            {
                Caption = 'Calculation Log';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "Safety Stock Calculation Log";
                ToolTip = 'Open the Safety Stock Calculation Log to review past calculation runs (all items, all users).';
            }
        }
        area(Promoted)
        {
            actionref(OpenLog_Promoted; OpenLog)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}

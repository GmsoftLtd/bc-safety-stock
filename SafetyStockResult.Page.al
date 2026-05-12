page 50101 "Safety Stock Calculation Log"
{
    Caption = 'Safety Stock Calculation Log';
    PageType = List;
    SourceTable = "Safety Stock Calculation Log";
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Calculation DateTime"; Rec."Calculation DateTime") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Result Code"; Rec."Result Code") { ApplicationArea = All; }
                field("Service Level %"; Rec."Service Level %") { ApplicationArea = All; }
                field("Calculated Safety Stock"; Rec."Calculated Safety Stock") { ApplicationArea = All; }
                field("Previous Safety Stock"; Rec."Previous Safety Stock") { ApplicationArea = All; }
                field("Avg Daily Demand"; Rec."Avg Daily Demand") { ApplicationArea = All; }
                field("Demand StdDev"; Rec."Demand StdDev") { ApplicationArea = All; }
                field("Lead Time (Days)"; Rec."Lead Time (Days)") { ApplicationArea = All; }
                field("Lead Time StdDev"; Rec."Lead Time StdDev") { ApplicationArea = All; }
                field("Demand Observations"; Rec."Demand Observations") { ApplicationArea = All; }
                field("Z-Score"; Rec."Z-Score") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}

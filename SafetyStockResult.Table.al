table 50101 "Safety Stock Calculation Log"
{
    Caption = 'Safety Stock Calculation Log';
    DataClassification = CustomerContent;
    LookupPageId = "Safety Stock Calculation Log";
    DrillDownPageId = "Safety Stock Calculation Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item;
        }
        field(3; "Calculation DateTime"; DateTime)
        {
            Caption = 'Calculation DateTime';
            DataClassification = CustomerContent;
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(10; "Service Level %"; Decimal)
        {
            Caption = 'Service Level %';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
        }
        field(11; "Z-Score"; Decimal)
        {
            Caption = 'Z-Score';
            DataClassification = CustomerContent;
            DecimalPlaces = 4 : 4;
        }
        field(20; "Avg Daily Demand"; Decimal)
        {
            Caption = 'Avg Daily Demand';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }
        field(21; "Demand StdDev"; Decimal)
        {
            Caption = 'Demand StdDev';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }
        field(22; "Lead Time (Days)"; Decimal)
        {
            Caption = 'Avg Lead Time (Days)';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
        }
        field(23; "Lead Time StdDev"; Decimal)
        {
            Caption = 'Lead Time StdDev';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;
        }
        field(24; "Demand Observations"; Integer)
        {
            Caption = 'Demand Observations';
            DataClassification = CustomerContent;
        }
        field(30; "Calculated Safety Stock"; Decimal)
        {
            Caption = 'Calculated Safety Stock';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(31; "Previous Safety Stock"; Decimal)
        {
            Caption = 'Previous Safety Stock';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(40; "Result Code"; Enum "Safety Stock Result Code")
        {
            Caption = 'Result Code';
            DataClassification = CustomerContent;
        }
        field(41; "Note"; Text[250])
        {
            Caption = 'Note';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Item; "Item No.", "Calculation DateTime") { }
    }
}

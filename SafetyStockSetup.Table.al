table 50100 "Safety Stock Setup"
{
    Caption = 'Safety Stock Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Default Service Level %"; Decimal)
        {
            Caption = 'Default Service Level %';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            MinValue = 50;
            MaxValue = 99.99;
            InitValue = 95;
        }
        field(11; "History Window (Days)"; Integer)
        {
            Caption = 'Demand History Window (Days)';
            DataClassification = CustomerContent;
            MinValue = 30;
            MaxValue = 730;
            InitValue = 180;
        }
        field(12; "Min Demand Observations"; Integer)
        {
            Caption = 'Min Demand Observations to Calculate';
            DataClassification = CustomerContent;
            MinValue = 3;
            InitValue = 10;
        }
        field(13; "Round Up Result"; Boolean)
        {
            Caption = 'Round Up Result to Whole Units';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(14; "Update Item Field"; Boolean)
        {
            Caption = 'Auto-Update Item.Safety Stock Quantity';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(15; "Log History"; Boolean)
        {
            Caption = 'Log Calculation History';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}

enum 50100 "Safety Stock Result Code"
{
    Extensible = true;

    value(0; OK)
    {
        Caption = 'OK';
    }
    value(1; "Insufficient Demand Data")
    {
        Caption = 'Insufficient Demand Data';
    }
    value(2; "No Lead Time Data")
    {
        Caption = 'No Lead Time Data';
    }
    value(3; "Item Blocked")
    {
        Caption = 'Item Blocked';
    }
    value(4; "Skipped By Filter")
    {
        Caption = 'Skipped By Filter';
    }
    value(99; Error)
    {
        Caption = 'Error';
    }
}

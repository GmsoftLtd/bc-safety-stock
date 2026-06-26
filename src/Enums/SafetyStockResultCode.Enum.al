/// <summary>
/// Outcome codes for a Safety Stock calculation, indicating whether it succeeded
/// or why it was skipped (insufficient demand, no lead time, item blocked, etc.).
/// </summary>
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

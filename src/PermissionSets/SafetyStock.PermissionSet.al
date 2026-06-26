/// <summary>
/// Full (RIMD) access permission set for the Safety Stock extension's setup and
/// calculation log tables.
/// </summary>
permissionset 50100 "Safety Stock"
{
    Assignable = true;
    Caption = 'Safety Stock - All';

    Permissions = tabledata "Safety Stock Setup" = RIMD,
                  tabledata "Safety Stock Calculation Log" = RIMD;
}

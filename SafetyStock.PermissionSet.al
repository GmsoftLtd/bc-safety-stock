permissionset 50100 "Safety Stock"
{
    Assignable = true;
    Caption = 'Safety Stock - All';

    Permissions = tabledata "Safety Stock Setup" = RIMD,
                  tabledata "Safety Stock Calculation Log" = RIMD;
}

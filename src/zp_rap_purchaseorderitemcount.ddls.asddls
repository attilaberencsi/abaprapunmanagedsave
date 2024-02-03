@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Hilfsview für erste Bestellposition'
define view entity ZP_RAP_PurchaseOrderItemCount
  as select from I_PurchaseOrderItemAPI01
{
  PurchaseOrder,
  min( PurchaseOrderItem ) as FirstPurchaseOrderItem
}
group by
  PurchaseOrder
having
  count(*) = 1

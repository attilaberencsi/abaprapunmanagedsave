@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Bestellung mit einer Position'
define root view entity ZI_RAP_PurchaseOrder_M
  as select from I_PurchaseOrderItemAPI01      as item
    inner join   ZP_RAP_PurchaseOrderItemCount as item_cnt on  item.PurchaseOrder     = item_cnt.PurchaseOrder
                                                           and item.PurchaseOrderItem = item_cnt.FirstPurchaseOrderItem
    inner join   ZI_RAP_PO_Material            as po_mat   on po_mat.Material = item.Material

  association [1] to I_PurchaseOrderAPI01     as _PurchaseOrder     on  _PurchaseOrder.PurchaseOrder = item.PurchaseOrder
  association [1] to I_PurchaseOrderItemAPI01 as _PurchaseOrderItem on  _PurchaseOrderItem.PurchaseOrder     = $projection.PurchaseOrder
                                                                    and _PurchaseOrderItem.PurchaseOrderItem = $projection.PurchaseOrderItem
  association [1] to ZI_RAP_PO_Material       as _POMaterial        on  _POMaterial.Material = $projection.Material

{
  key item.PurchaseOrder,
      _PurchaseOrder.PurchaseOrderType,
      _PurchaseOrder.PurchaseOrderDate,
      _PurchaseOrder.PurchasingOrganization,
      _PurchaseOrder.PurchasingGroup,
      _PurchaseOrder.Supplier,
      _PurchaseOrder.CreatedByUser,
      _PurchaseOrder.CreationDate,
      _PurchaseOrder.LastChangeDateTime,
      item.PurchaseOrderItem,

      item.Material,
      item.OrderQuantity,
      item.PurchaseOrderQuantityUnit,
      item.Plant,

      _PurchaseOrder,
      _PurchaseOrderItem,
      _POMaterial
}
where
  item.PurchasingDocumentDeletionCode <> 'L'

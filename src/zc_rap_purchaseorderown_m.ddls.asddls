@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Meine Bestellungen'
@Metadata.allowExtensions: true
// (4) SortOrder Annotation wird nicht für ResponsiveTable angewendet
// Quelle: https://sapui5.hana.ondemand.com/#/api/sap.ui.comp.smarttable.SmartTable%23annotations/PresentationVariant
@UI.presentationVariant: [{ id: 'DEFAULT', qualifier: 'DEFAULT', sortOrder: [{ by: 'PurchaseOrder', direction: #DESC }] }]
define root view entity ZC_RAP_PurchaseOrderOwn_M
  as projection on ZI_RAP_PurchaseOrder_M
{
  key PurchaseOrder,
      PurchaseOrderItem,
      Plant,
      PurchaseOrderDate,
      @ObjectModel.text.element: ['MaterialName']
      Material,
      _POMaterial._Material._Text.MaterialName as MaterialName : localized,
      OrderQuantity,
      PurchaseOrderQuantityUnit,
      /* Associations */
      _POMaterial,
      _PurchaseOrder,
      _PurchaseOrderItem
}
// (1) Bestellung nur für aktuellen Benutzer lesen
where
  CreatedByUser = $session.user

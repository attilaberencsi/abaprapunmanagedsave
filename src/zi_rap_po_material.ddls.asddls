@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Gültiges Material für Schnellerfassung'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_RAP_PO_Material
  as select from zrap_a_po_mat
  association [0..1] to I_Material             as _Material      on _Material.Material = $projection.Material
  association [0..1] to I_Supplier             as _Supplier      on _Supplier.Supplier = $projection.Supplier
{
  key material        as Material,
      supplier        as Supplier,
      is_active       as IsActive,
      created_by      as CreatedBy,
      created_at      as CreatedAt,
      last_changed_by as LastChangedBy,
      last_changed_at as LastChangedAt,
      _Material,
      _Supplier
}

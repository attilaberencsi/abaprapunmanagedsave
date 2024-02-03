@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Gültige Materialien, Suchhilfe'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
// Wertehilfe als Dropdown darstellen
//@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_RAP_PO_MaterialActive_VH
  as select from ZI_RAP_PO_Material
{
      @ObjectModel.text.association: '_MaterialText'
  key Material,
      _Material.MaterialBaseUnit as MaterialBaseUnit,
      @Consumption.hidden: true
      _Material.Material         as MaterialForText,
      _Material._Text            as _MaterialText
}
where
  IsActive = 'X'

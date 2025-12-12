@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Request Item projection view'
@Metadata.allowExtensions: true

define view entity ZC_RequestItem
  as projection on ZI_RequestItem
{
  key RequestUuid,
  key ItemUuid,
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_PRODUCT_VH',
                  element: 'ProductId' } }]  
      ProductId,
      ProductQty,
      ProductUom,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      
      /* Associations */
      _Request as request : redirected to parent ZC_Request
}

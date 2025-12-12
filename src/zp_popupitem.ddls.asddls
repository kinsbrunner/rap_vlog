@EndUserText.label: 'Entity for item creation'

define root abstract entity ZP_PopupItem
{
      @EndUserText.label: 'Product ID'
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_PRODUCT_VH',
                  element: 'ProductId' } }]        
      ProductId     : matnr;
      @EndUserText.label: 'Amount'
      @Semantics.quantity.unitOfMeasure : 'ProductUom'
      ProductAmount : kwmeng;
      @EndUserText.label: 'Unit'      
      ProductUom    : vrkme;
}

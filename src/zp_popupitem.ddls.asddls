@EndUserText.label: 'Entity for item creation'

define root abstract entity ZP_PopupItem
{
      @EndUserText.label: 'Product ID'
      ProductId     : matnr;
      @EndUserText.label: 'Amount'
      @Semantics.quantity.unitOfMeasure : 'ProductUom'
      ProductAmount : kwmeng;
      @EndUserText.label: 'Unit'      
      ProductUom    : vrkme;
}

@EndUserText.label: 'Entity for item creation'

define abstract entity ZP_PopupItem
{
      ProductId     : matnr;
      @EndUserText.label: 'Amount'
      @Semantics.quantity.unitOfMeasure : 'ProductUom'
      ProductAmount : kwmeng;
      ProductUom    : vrkme;
}

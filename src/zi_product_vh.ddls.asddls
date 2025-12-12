@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product value help'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZI_Product_VH
  as select from zrap_c_products
{
      @ObjectModel.text.element: [ 'ProductName' ]
  key product     as ProductId,
      description as ProductName
}
where is_available = 'X'


//define view entity ZI_Product_VH
//  as select from zrap_c_product as conf
//    inner join   I_Product      as prod on conf.product = prod.Product
//{
//      @ObjectModel.text.element: [ 'ProductName' ]
//  key prod.Product                                                    as ProductId,
//      prod._Text[1: Language = $session.system_language ].ProductName as ProductName
//}
//where conf.is_available = 'X'

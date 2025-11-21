@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Priority value help'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZI_Priority_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name: 'ZRAP_PRIORITY_D' )   as Values
    inner join   DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZRAP_PRIORITY_D' ) as Texts on  Values.domain_name = Texts.domain_name
                                                                                            and Values.value_low   = Texts.value_low
                                                                                            and Texts.language     = $session.system_language
{

      @ObjectModel.text.element: [ 'PriorityText' ]
  key Values.value_low as PriorityCode,
      Texts.text       as PriorityText

}

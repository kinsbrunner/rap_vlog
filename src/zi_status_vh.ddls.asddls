@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Status value help'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZI_Status_VH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE( p_domain_name: 'ZRAP_STATUS_D' )   as Values
    inner join   DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZRAP_STATUS_D' ) as Texts on  Values.domain_name = Texts.domain_name
                                                                                          and Values.value_low   = Texts.value_low
                                                                                          and Texts.language     = $session.system_language
{

      @ObjectModel.text.element: [ 'StatusText' ]
  key Values.value_low as StatusCode,
      Texts.text       as StatusText

}

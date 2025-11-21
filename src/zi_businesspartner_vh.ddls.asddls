@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Partner value help'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_BusinessPartner_VH
  as select from I_BusinessPartnerVH
{
      @ObjectModel.text.element: [ 'BusinessPartnerName' ]
  key BusinessPartner,
      BusinessPartnerName,
      FirstName,
      LastName
}
where FirstName is not initial

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Request projection view'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_Request
  provider contract transactional_query
  as projection on ZI_Request
{
  key RequestUuid,
      @Search.defaultSearchElement: true  
      ExternalId,
      @Search.defaultSearchElement: true
      Status,
      StatusCriticality,
      @Search.defaultSearchElement: true
      Priority,
      DeadlineDate,
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'RequesterName' ]
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_BusinessPartner_VH',
                  element: 'BusinessPartner'} }]
      RequesterId,
      _requester.BusinessPartnerName as RequesterName,
      CancelReason,
      LastChangedAt,

      /* Associations */
      _items as items: redirected to composition child ZC_RequestItem
}

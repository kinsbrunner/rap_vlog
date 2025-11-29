@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Request projection view'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'ExternalId' ]

define root view entity ZC_Request
  provider contract transactional_query
  as projection on ZI_Request
{
  key RequestUuid,
  
      @Search.defaultSearchElement: true
      ExternalId,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'StatusText' ]
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_Status_VH',
                  element: 'StatusCode'} }]
      Status,
      _status.StatusText             as StatusText,
      StatusCriticality,

      @Search.defaultSearchElement: true
      @Consumption.filter.selectionType: #SINGLE
      @ObjectModel.text.element: [ 'PriorityText' ]
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_Priority_VH',
                  element: 'PriorityCode'} }]
      Priority,
      _priority.PriorityText         as PriorityText,
 
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'RequesterName' ]
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_BusinessPartner_VH',
                  element: 'BusinessPartner'} }]
      RequesterId,
      _requester.BusinessPartnerName as RequesterName,
 
      DeadlineDate,
      CancelReason,
      LastChangedAt,

      /* Associations */
      _items                         as items : redirected to composition child ZC_RequestItem
}

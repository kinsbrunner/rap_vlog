@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Request projection view'
@Metadata.allowExtensions: true

define root view entity ZC_Request
  provider contract transactional_query
  as projection on ZI_Request
{
  key RequestUuid,
      ExternalId,
      Status,
      StatusCriticality,
      Priority,
      DeadlineDate,
      RequesterId,
      CancelReason,
      LastChangedAt,

      /* Associations */
      _items as items: redirected to composition child ZC_RequestItem
}

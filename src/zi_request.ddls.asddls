@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Request interface view'
define root view entity ZI_Request
  as select from zrap_a_request

  composition [0..*] of ZI_RequestItem    as _items
  association [0..1] to I_BusinessPartner as _requester on $projection.RequesterId = _requester.BusinessPartner
  association [0..1] to ZI_Priority_VH    as _priority  on $projection.Priority = _priority.PriorityCode
  association [0..1] to ZI_Status_VH      as _status    on $projection.Status = _status.StatusCode
{
  key request_uuid    as RequestUuid,
      status          as Status,
      priority        as Priority,
      external_id     as ExternalId,
      deadline_date   as DeadlineDate,
      requesterid     as RequesterId,
      cancel_reason   as CancelReason,
      @Semantics.user.createdBy: true
      created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,
      case status
        when '101' then 2
        when '102' then 3
        when '103' then 1
        else 0
      end             as StatusCriticality,

      //Associations
      _items,
      _requester,
      _priority,
      _status
}

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Status editing'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZI_Status_Edit_VH
  as select from ZI_Status_VH
{
      @ObjectModel.text.element: [ 'StatusText' ]
  key StatusCode,
      StatusText
}
where StatusCode != '103' //Cancelled 

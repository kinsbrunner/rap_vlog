CLASS lhc_Request DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Request RESULT result.


ENDCLASS.

CLASS lhc_Request IMPLEMENTATION.

  METHOD get_instance_authorizations.
    "Will not be implemented for now
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Request DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Request RESULT result.

    METHODS set_semantic_key FOR DETERMINE ON SAVE
      IMPORTING keys FOR request~set_semantic_key.
    METHODS check_semantic_key FOR VALIDATE ON SAVE
      IMPORTING keys FOR request~check_semantic_key.


ENDCLASS.

CLASS lhc_Request IMPLEMENTATION.

  METHOD get_instance_authorizations.
    "Will not be implemented for now
  ENDMETHOD.

  METHOD set_semantic_key.
    CONSTANTS c_object TYPE cl_numberrange_objects=>nr_attributes-object   VALUE 'ZRAP_REQUE'.

    TRY.
        cl_numberrange_runtime=>number_get( EXPORTING nr_range_nr = '01'
                                                      object      = c_object
                                            IMPORTING number      = DATA(lv_number)
                                                      returncode  = DATA(lv_rcode) ).

        "Assign generated number into the new Request
        MODIFY ENTITIES OF ZI_Request IN LOCAL MODE
        ENTITY Request
        UPDATE
        FIELDS ( ExternalId )
        WITH VALUE #( FOR ls_key IN keys
                      ( %key = ls_key-%key
                        ExternalId = lv_number ) )
        REPORTED DATA(ls_result).

      CATCH cx_root INTO DATA(lo_error).
        "Error handling to be implemented here!

    ENDTRY.
  ENDMETHOD.


  METHOD check_semantic_key.
    READ ENTITIES OF ZI_Request IN LOCAL MODE
      ENTITY Request
      FIELDS ( ExternalId )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing).

    SELECT
      FROM ZI_Request AS db
      INNER JOIN @lt_existing AS local ON local~RequestUuid <> db~RequestUuid
                                       AND local~ExternalId = db~ExternalId
      FIELDS db~RequestUuid,
             db~ExternalId,
             local~RequestUuid AS LocalUuid
      INTO TABLE @DATA(lt_duplicates).

    LOOP AT lt_duplicates INTO DATA(ls_duplicate).
      INSERT VALUE #( RequestUuid = ls_duplicate-localuuid ) INTO TABLE failed-request.
      INSERT VALUE #( RequestUuid = ls_duplicate-localuuid
                      %msg        = new_message( id       = 'ZMSG_REQUEST'
                                                 number   = '002'
                                                 severity = if_abap_behv_message=>severity-error
                                                 v1       = ls_duplicate-ExternalId ) ) INTO TABLE reported-request.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

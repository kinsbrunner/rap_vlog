CLASS lhc_Request DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Request RESULT result.

    METHODS set_semantic_key FOR DETERMINE ON SAVE
      IMPORTING keys FOR request~set_semantic_key.
    METHODS check_semantic_key FOR VALIDATE ON SAVE
      IMPORTING keys FOR request~check_semantic_key.
    METHODS check_mandatory_fields FOR VALIDATE ON SAVE
      IMPORTING keys FOR request~check_mandatory_fields.
    METHODS check_deadline_date FOR VALIDATE ON SAVE
      IMPORTING keys FOR request~check_deadline_date.
    METHODS set_priority FOR DETERMINE ON MODIFY
      IMPORTING keys FOR request~set_priority.
    METHODS set_initial_status FOR DETERMINE ON MODIFY
      IMPORTING keys FOR request~set_initial_status.


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


  METHOD check_mandatory_fields.
    DATA permission_request TYPE STRUCTURE FOR PERMISSIONS REQUEST ZI_Request.
    DATA reported_zi_request_li LIKE LINE OF reported-request.

    DATA(description_permission_request) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data_ref( REF #( permission_request-%field ) ) ).
    DATA(components_permission_request) = description_permission_request->get_components( ).

    LOOP AT components_permission_request INTO DATA(component_permission_Request).
      permission_request-%field-(component_permission_request-name) = if_abap_behv=>mk-on.
    ENDLOOP.

    " Get current field values
    READ ENTITIES OF ZI_Request IN LOCAL MODE
    ENTITY Request
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT lt_requests INTO DATA(ls_request).

      GET PERMISSIONS ONLY INSTANCE FEATURES ENTITY ZI_Request
        FROM VALUE #( ( RequestUuid = ls_request-RequestUuid ) )
        REQUEST permission_request
        RESULT DATA(permission_result)
        FAILED DATA(failed_permission_result)
        REPORTED DATA(reported_permission_result).

      LOOP AT components_permission_request INTO component_permission_request.
        " Permission result for the global information ( field ( mandatory ) DeadlineDate; ) is stored in a structure.

        IF permission_result-global-%field-(component_permission_request-name) = if_abap_behv=>fc-f-mandatory AND
           ls_request-(component_permission_request-name) IS INITIAL.

          APPEND VALUE #( %tky = ls_request-%tky ) TO failed-request.

          " Since %element-(component_permission_request-name) = if_abap_behv=>mk-on could not be added using a VALUE statement
          "  add the value via assigning value to the field of a structure

          CLEAR reported_zi_request_li.
          reported_zi_request_li-%tky = ls_request-%tky.
          reported_zi_request_li-%element-(component_permission_Request-name) = if_abap_behv=>mk-on.
          reported_zi_request_li-%msg = new_message( id = 'ZMSG_REQUEST'
                                                         number = 001
                                                         severity = if_Abap_behv_message=>severity-error
                                                         v1 = |{ component_permission_request-name }|
                                                         v2 = |{ ls_request-ExternalId }| ).

          APPEND reported_zi_request_li TO reported-request.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD check_deadline_date.
    READ ENTITIES OF ZI_Request IN LOCAL MODE
      ENTITY Request
      FIELDS ( DeadlineDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    DATA lv_min_date  TYPE d.
    lv_min_date = sy-datum + 1.

    LOOP AT lt_requests INTO DATA(ls_request).
      IF ls_request-DeadlineDate < lv_min_date.
        INSERT VALUE #( RequestUuid = ls_request-RequestUuid ) INTO TABLE failed-request.
        INSERT VALUE #( RequestUuid = ls_request-RequestUuid
                        %msg        = new_message( id       = 'ZMSG_REQUEST'
                                                   number   = '003'
                                                   severity = if_abap_behv_message=>severity-error
                                                   v1       = |{ ls_request-DeadlineDate DATE = USER }| ) ) INTO TABLE reported-request.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD set_priority.
    READ ENTITIES OF ZI_Request IN LOCAL MODE
    ENTITY Request
    FIELDS ( RequestUuid DeadlineDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    MODIFY ENTITIES OF ZI_Request IN LOCAL MODE
    ENTITY Request
    UPDATE
    FIELDS ( Priority )
    WITH VALUE #( FOR ls_request IN lt_requests
                  ( %key = ls_request-%key
                    Priority = COND #( WHEN ls_request-DeadlineDate - sy-datum < 3 THEN 1
                                       WHEN ls_request-DeadlineDate - sy-datum < 7 THEN 2
                                       ELSE 3 ) ) )
    REPORTED DATA(ls_result).
  ENDMETHOD.


  METHOD set_initial_status.
    MODIFY ENTITIES OF ZI_Request IN LOCAL MODE
    ENTITY Request
    UPDATE
    FIELDS ( Status )
    WITH VALUE #( FOR ls_key IN keys
                  ( %key = ls_key-%key
                    Status = 100 ) )
    REPORTED DATA(ls_result).
  ENDMETHOD.

ENDCLASS.

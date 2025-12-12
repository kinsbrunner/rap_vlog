CLASS cx_invalid_product DEFINITION
  INHERITING FROM cx_static_check
  FINAL.
  PUBLIC SECTION.
    DATA product_id TYPE matnr.
    METHODS constructor
      IMPORTING
        product_id TYPE matnr.
ENDCLASS.

CLASS cx_invalid_product IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->product_id = product_id.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_request_validation DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_product
      IMPORTING iv_product        TYPE matnr
      RETURNING VALUE(rs_product) TYPE zrap_c_products
      RAISING   cx_invalid_product.
ENDCLASS.

CLASS lcl_request_validation IMPLEMENTATION.
  METHOD get_product.

    SELECT SINGLE
      FROM zrap_c_products
      FIELDS *
      WHERE product = @iv_product
      INTO @rs_product.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_invalid_product
        EXPORTING
          product_id = iv_product.
    ENDIF.

  ENDMETHOD.
ENDCLASS.

CLASS lhc_requestitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE RequestItem.

ENDCLASS.

CLASS lhc_requestitem IMPLEMENTATION.

  METHOD precheck_update.
    " Unless called through consumer using EML, not expecting to get multiple entries
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).

      " Skip cases where ProductId was not touched
      IF <ls_entity>-%control-ProductId = if_abap_behv=>mk-off.
        CONTINUE.
      ENDIF.

      TRY.
          " Central check (lookup + availability)
          DATA(ls_product) = lcl_request_validation=>get_product( iv_product = <ls_entity>-ProductId ).

          " Is product available in the config table?
          IF ls_product-is_available EQ abap_false.
            APPEND VALUE #( %cid = <ls_entity>-%cid_ref ) TO failed-requestitem.
            APPEND VALUE #( %cid = <ls_entity>-%cid_ref
                            %msg = new_message( id       = 'ZMSG_REQUEST'
                                                number   = '005'
                                                severity = if_abap_behv_message=>severity-error
                                                v1       = |{ <ls_entity>-ProductId ALPHA = OUT }| ) ) TO reported-requestitem.
          ENDIF.

        CATCH cx_invalid_product INTO DATA(lx).
          " Product does not exist
          APPEND VALUE #( %cid = <ls_entity>-%cid_ref ) TO failed-requestitem.
          APPEND VALUE #( %cid = <ls_entity>-%cid_ref
                          %msg = new_message( id       = 'ZMSG_REQUEST'
                                              number   = '004'
                                              severity = if_abap_behv_message=>severity-error
                                              v1       = |{ <ls_entity>-ProductId ALPHA = OUT }| ) ) TO reported-requestitem.

      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

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
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR request RESULT result.
    METHODS cancel_request FOR MODIFY
      IMPORTING keys FOR ACTION request~cancel_request.
    METHODS add_item FOR MODIFY
      IMPORTING keys FOR ACTION request~add_item.
    METHODS precheck_cba_items FOR PRECHECK
      IMPORTING entities FOR CREATE request\_items.


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
        " Permission result for instances (field ( features : instance ) CancelReason;) is stored in an internal table.

        IF ( permission_result-global-%field-(component_permission_request-name) = if_abap_behv=>fc-f-mandatory OR
             permission_result-instances[ RequestUuid = ls_request-RequestUuid ]-%field-(component_permission_request-name) = if_abap_behv=>fc-f-mandatory ) AND
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


  METHOD get_instance_features.
    " Get the root node. In a Fiori Elements UI this will be just one entry. But, when being called via EML or as an API,
    "  several instances of Request can be requested.
    READ ENTITIES OF ZI_Request IN LOCAL MODE
      ENTITY Request
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    " Loop the nodes and set the Mandatory field either to read-only or mandatory based on the
    "  value of Status field
    LOOP AT lt_requests INTO DATA(ls_request).
      APPEND VALUE #( %tky = ls_request-%tky
                      " This is for preventing Status from being set during Create
                      %field-Status       = COND #( WHEN ls_request-ExternalId IS INITIAL
                                                    THEN if_abap_behv=>fc-f-read_only
                                                    ELSE if_abap_behv=>fc-f-unrestricted )
                      " This is for marking the CancelReason as mandatory when Status is Cancelled
                      %field-CancelReason = COND #( WHEN ls_request-Status = 103 "Cancelled
                                                    THEN if_abap_behv=>fc-f-mandatory
                                                    ELSE if_abap_behv=>fc-f-unrestricted )
                     " This is for disabling the edit of header fields, for a cancelled request
                     %update   = COND #( WHEN ls_request-Status = 103
                                         THEN if_abap_behv=>fc-o-disabled
                                         ELSE if_abap_behv=>fc-o-enabled )
                     " This is for disabling the Create button of the children
                     %assoc-_items       = COND #( WHEN ls_request-Status = 103
                                                   THEN if_abap_behv=>fc-o-disabled
                                                   ELSE if_abap_behv=>fc-o-enabled )
                     " This is for disabling the draft Edit button
                     %action-Edit = COND #( WHEN ls_request-Status = 103
                                            THEN if_abap_behv=>fc-o-disabled
                                            ELSE if_abap_behv=>fc-o-enabled )
                     " This is for disabling the Cancel custom action, for the already cancelled requests
                     %action-cancel_request = COND #( WHEN ls_request-Status = 103
                                                      THEN if_abap_behv=>fc-o-disabled
                                                      ELSE if_abap_behv=>fc-o-enabled )
                     " This is for disabling the Add Item button when the BO is under draft mode and not active
                     %action-add_item       = COND #( WHEN ls_request-%is_draft   = '01'
                                                      THEN if_abap_behv=>fc-o-disabled
                                                      ELSE if_abap_behv=>fc-o-enabled ) ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD cancel_request.
    READ ENTITIES OF ZI_Request IN LOCAL MODE
    ENTITY Request
    FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    MODIFY ENTITIES OF ZI_Request IN LOCAL MODE
    ENTITY Request
    UPDATE
    FIELDS ( Status CancelReason )
    WITH VALUE #( FOR ls_request IN lt_Requests
                  ( %key = ls_request-%key
                    Status = '103'
                    CancelReason = keys[ RequestUuid = ls_request-RequestUuid ]-%param-cancel_reason ) )
    REPORTED DATA(ls_result).
  ENDMETHOD.


  METHOD add_item.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      DATA(lv_product) = <ls_key>-%param-ProductId.

      TRY.
          " Central lookup + availability check
          DATA(ls_product) = lcl_request_validation=>get_product( iv_product = lv_product ).

          " Exists but not available
          IF ls_product-is_available = abap_false.
            APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-request.
            APPEND VALUE #( %tky = <ls_key>-%tky
                            %msg = new_message( id       = 'ZMSG_REQUEST'
                                                number   = '005'
                                                severity = if_abap_behv_message=>severity-error
                                                v1       = |{ lv_product ALPHA = OUT }| ) ) TO reported-request.
          ENDIF.

        CATCH cx_invalid_product INTO DATA(lx).
          " Product does not exist in config table
          APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-request.
          APPEND VALUE #( %tky = <ls_key>-%tky
                          %msg = new_message( id       = 'ZMSG_REQUEST'
                                              number   = '004'
                                              severity = if_abap_behv_message=>severity-error
                                              v1       = |{ lv_product ALPHA = OUT }| ) ) TO reported-request.
      ENDTRY.
    ENDLOOP.

    MODIFY ENTITIES OF zi_request IN LOCAL MODE
      ENTITY Request
        CREATE BY \_items
        FROM VALUE #( FOR ls_key IN keys INDEX INTO lv_idx
                        ( %tky    = ls_key-%tky
                          %target = VALUE #(
                                      ( %cid = |NEW_ITEM_{ lv_idx }|
                                        ProductId  = ls_key-%param-ProductId
                                        ProductQty = ls_key-%param-ProductAmount
                                        ProductUom = ls_key-%param-ProductUom
                                        %control = VALUE #(
                                          ProductId  = if_abap_behv=>mk-on
                                          ProductQty = if_abap_behv=>mk-on
                                          ProductUom = if_abap_behv=>mk-on ) ) ) ) )
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).

  ENDMETHOD.

  METHOD precheck_cba_Items.
    " Not needed for our educational scenario as system creates an empty entity and then,
    "  it just uses the UPDATE so precheck should only go there!
  ENDMETHOD.

ENDCLASS.

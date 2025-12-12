CLASS zcl_rap_auxiliary_cust DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS fill_customizing_products
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out.
ENDCLASS.



CLASS zcl_rap_auxiliary_cust IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    fill_customizing_products( out ).
  ENDMETHOD.

  METHOD fill_customizing_products.
    DATA lt_records TYPE TABLE OF zrap_c_products.

    lt_records = VALUE #(
      ( product = CONV matnr( |{ '1111' ALPHA = IN }| ) is_available = abap_true  description = 'Printer' )
      ( product = CONV matnr( |{ '2222' ALPHA = IN }| ) is_available = abap_true  description = 'Headphones' )
      ( product = CONV matnr( |{ '3333' ALPHA = IN }| ) is_available = abap_false description = 'Microphone' )
    ).

    DELETE FROM zrap_c_products.
    INSERT zrap_c_products FROM TABLE @lt_records.

    io_out->write( 'Customizing has been updated!' ).
  ENDMETHOD.
ENDCLASS.
